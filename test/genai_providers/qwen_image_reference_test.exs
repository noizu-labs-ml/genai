defmodule GenAI.Provider.QwenImageReferenceTest do
  @moduledoc """
  Qwen Image reference-image (image+text -> image) encoding, ported from the proven
  media-tools Rust multimodal body. Finch is mocked via Mimic; asserts the wire body
  (data-URL image parts first, text last, <=3 attachments), parameters, the five
  response URL shapes, and connection-drop retry. The real provider call lives in
  qwen_image_reference_live_test.exs (@tag :live).
  """
  use ExUnit.Case, async: false
  use Mimic

  alias GenAI.Media.Request
  alias GenAI.Message.Content.ImageContent
  alias GenAI.Provider.Qwen.Image, as: QwenImage

  @png <<137, 80, 78, 71, 13, 10, 26, 10>>
  @png_b64 Base.encode64(@png)
  @multimodal_path "/api/v1/services/aigc/multimodal-generation/generation"
  @out_url "https://dashscope-result.example.com/out.png"

  setup do
    keys = ~w(DASHSCOPE_API_KEY QWEN_API_KEY QWEN_TOKEN_KEY)
    saved = Map.new(keys, &{&1, System.get_env(&1)})
    Enum.each(keys, &System.delete_env/1)

    on_exit(fn ->
      Enum.each(saved, fn
        {k, nil} -> System.delete_env(k)
        {k, v} -> System.put_env(k, v)
      end)
    end)

    :ok
  end

  defp image(b64 \\ @png_b64, type \\ :png),
    do: ImageContent.new({:base64, b64}, type: type)

  defp ok_image_response(url \\ @out_url) do
    {:ok,
     %Finch.Response{
       status: 200,
       body:
         Jason.encode!(%{
           output: %{choices: [%{message: %{content: [%{image: url}]}}]}
         })
     }}
  end

  # Route by path: the multimodal POST returns an image URL; the result GET returns bytes.
  defp stub_media(post_fun) do
    stub(Finch, :request, fn req, GenAI.Finch, _opts ->
      cond do
        req.path == @multimodal_path -> post_fun.(req)
        req.path == "/out.png" -> {:ok, %Finch.Response{status: 200, body: @png}}
        true -> flunk("unexpected request path: #{req.path}")
      end
    end)
  end

  defp decode_body(req), do: Jason.decode!(req.body)

  describe "modality + fast fail" do
    test "declares text/image -> image sync" do
      assert [%{input: [:text, :image], output: :image, mode: :sync}] =
               QwenImage.supported_modalities()
    end

    test "no key -> fast fail even with an image prompt" do
      assert {:error, :missing_api_key} =
               QwenImage.generate_media(
                 %Request{output: :image, prompt: [image(), "edit"]},
                 []
               )
    end
  end

  describe "reference-image wire body" do
    test "encodes data-URL image part first, text part last, with model + size" do
      stub_media(fn req ->
        body = decode_body(req)
        assert body["model"] == "qwen-image-3.0-pro"
        assert req.method == "POST"
        content = get_in(body, ["input", "messages", Access.at(0), "content"])
        assert [%{"image" => image_url}, %{"text" => "make it blue"}] = content
        assert image_url == "data:image/png;base64,#{@png_b64}"
        assert get_in(body, ["parameters", "size"]) == "1600*900"
        ok_image_response()
      end)

      assert {:ok, %{data: @png, mime: "image/png", meta: %{url: @out_url}}} =
               QwenImage.generate_media(
                 %Request{
                   output: :image,
                   model: "qwen-image-3.0-pro",
                   prompt: [image(), "make it blue"],
                   api_key: "sk-test",
                   settings: %{size: "1600x900"}
                 },
                 []
               )
    end

    test "caps reference images at 3" do
      stub_media(fn req ->
        content = get_in(decode_body(req), ["input", "messages", Access.at(0), "content"])
        images = Enum.filter(content, &Map.has_key?(&1, "image"))
        assert length(images) == 3
        assert List.last(content) == %{"text" => "edit"}
        ok_image_response()
      end)

      assert {:ok, _} =
               QwenImage.generate_media(
                 %Request{
                   output: :image,
                   prompt: [image(), image(), image(), image(), "edit"],
                   api_key: "sk-test"
                 },
                 []
               )
    end

    test "jpeg mime reflects the image type" do
      stub_media(fn req ->
        [%{"image" => url} | _] =
          get_in(decode_body(req), ["input", "messages", Access.at(0), "content"])

        assert String.starts_with?(url, "data:image/jpeg;base64,")
        ok_image_response()
      end)

      assert {:ok, _} =
               QwenImage.generate_media(
                 %Request{
                   output: :image,
                   prompt: [image(@png_b64, :jpeg), "edit"],
                   api_key: "sk-test"
                 },
                 []
               )
    end

    test "text-only prompt still rides the multimodal route" do
      stub_media(fn req ->
        content = get_in(decode_body(req), ["input", "messages", Access.at(0), "content"])
        assert content == [%{"text" => "a cat"}]
        ok_image_response()
      end)

      assert {:ok, %{data: @png}} =
               QwenImage.generate_media(
                 %Request{output: :image, prompt: "a cat", api_key: "sk-test"},
                 []
               )
    end

    test "uri reference image is downloaded and base64-encoded" do
      stub(Finch, :request, fn req, GenAI.Finch, _opts ->
        cond do
          req.path == "/ref.png" ->
            {:ok, %Finch.Response{status: 200, body: @png}}

          req.path == @multimodal_path ->
            [%{"image" => url} | _] =
              get_in(decode_body(req), ["input", "messages", Access.at(0), "content"])

            assert url == "data:image/png;base64,#{@png_b64}"
            ok_image_response()

          req.path == "/out.png" ->
            {:ok, %Finch.Response{status: 200, body: @png}}
        end
      end)

      assert {:ok, _} =
               QwenImage.generate_media(
                 %Request{
                   output: :image,
                   prompt: [
                     ImageContent.new({:uri, "https://ref.example.com/ref.png"}, type: :png),
                     "edit"
                   ],
                   api_key: "sk-test"
                 },
                 []
               )
    end
  end

  describe "parameters" do
    test "negative_prompt and n are forwarded" do
      stub_media(fn req ->
        params = decode_body(req)["parameters"]
        assert params["negative_prompt"] == "blurry"
        assert params["n"] == 2
        ok_image_response()
      end)

      assert {:ok, _} =
               QwenImage.generate_media(
                 %Request{
                   output: :image,
                   prompt: "a cat",
                   api_key: "sk-test",
                   settings: %{negative_prompt: "blurry", n: 2}
                 },
                 []
               )
    end

    test "aspect_ratio 4:3 maps to 1024*768" do
      stub_media(fn req ->
        assert decode_body(req)["parameters"]["size"] == "1024*768"
        ok_image_response()
      end)

      assert {:ok, _} =
               QwenImage.generate_media(
                 %Request{
                   output: :image,
                   prompt: "a cat",
                   api_key: "sk-test",
                   settings: %{aspect_ratio: "4:3"}
                 },
                 []
               )
    end
  end

  describe "response URL shapes" do
    test "reads output.results[0].url (async task-result shape)" do
      stub(Finch, :request, fn req, GenAI.Finch, _opts ->
        if req.path == @multimodal_path do
          {:ok,
           %Finch.Response{
             status: 200,
             body: Jason.encode!(%{output: %{results: [%{url: @out_url}]}})
           }}
        else
          {:ok, %Finch.Response{status: 200, body: @png}}
        end
      end)

      assert {:ok, %{data: @png, meta: %{url: @out_url}}} =
               QwenImage.generate_media(
                 %Request{output: :image, prompt: "a cat", api_key: "sk-test"},
                 []
               )
    end

    test "unexpected response shape -> :unexpected_response" do
      stub_media(fn _req ->
        {:ok, %Finch.Response{status: 200, body: Jason.encode!(%{output: %{}})}}
      end)

      assert {:error, :unexpected_response} =
               QwenImage.generate_media(
                 %Request{output: :image, prompt: "a cat", api_key: "sk-test"},
                 []
               )
    end
  end

  describe "transport" do
    test "non-200 surfaces http_error (no retry)" do
      stub_media(fn _req ->
        {:ok, %Finch.Response{status: 401, body: ~s({"error":"bad key"})}}
      end)

      assert {:error, {:http_error, 401, _}} =
               QwenImage.generate_media(
                 %Request{output: :image, prompt: "a cat", api_key: "sk-test"},
                 []
               )
    end

    test "retries a dropped connection then succeeds" do
      {:ok, counter} = Agent.start_link(fn -> 0 end)

      stub_media(fn _req ->
        n = Agent.get_and_update(counter, &{&1, &1 + 1})

        if n == 0 do
          {:error, %Finch.Error{reason: :closed}}
        else
          ok_image_response()
        end
      end)

      assert {:ok, %{data: @png}} =
               QwenImage.generate_media(
                 %Request{output: :image, prompt: "a cat", api_key: "sk-test"},
                 []
               )

      assert Agent.get(counter, & &1) == 2
    end

    test "gives up after exhausting connection retries" do
      stub_media(fn _req -> {:error, %Finch.Error{reason: :closed}} end)

      assert {:error, {:request_failed, %Finch.Error{reason: :closed}}} =
               QwenImage.generate_media(
                 %Request{output: :image, prompt: "a cat", api_key: "sk-test"},
                 []
               )
    end
  end
end