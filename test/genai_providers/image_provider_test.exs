defmodule GenAI.Provider.ImageProviderTest do
  @moduledoc """
  Sync image media providers (ADR-016 / ede43647): OpenAI gpt-image-1 + Gemini Imagen.
  Verifies the declared modality, the no-key fast-fail, and the happy path
  (Finch mocked via Mimic) decoding into the shared {:ok, %{data, mime, meta}} contract.
  """
  use ExUnit.Case, async: false
  use Mimic

  alias GenAI.Media.Request
  alias GenAI.Provider.OpenAI.Image, as: OpenAIImage
  alias GenAI.Provider.Gemini.Image, as: GeminiImage

  @png <<137, 80, 78, 71, 13, 10, 26, 10>>
  @png_b64 Base.encode64(@png)

  setup do
    # Snapshot + clear keys so no-key tests are deterministic regardless of host env.
    saved = {System.get_env("OPENAI_API_KEY"), System.get_env("GEMINI_API_KEY")}
    System.delete_env("OPENAI_API_KEY")
    System.delete_env("GEMINI_API_KEY")

    on_exit(fn ->
      {oa, gm} = saved
      if oa, do: System.put_env("OPENAI_API_KEY", oa), else: System.delete_env("OPENAI_API_KEY")
      if gm, do: System.put_env("GEMINI_API_KEY", gm), else: System.delete_env("GEMINI_API_KEY")
    end)

    :ok
  end

  describe "supported_modalities" do
    test "openai declares text -> image sync" do
      assert [%{input: [:text], output: :image, mode: :sync}] = OpenAIImage.supported_modalities()
    end

    test "gemini declares text -> image sync" do
      assert [%{input: [:text], output: :image, mode: :sync}] = GeminiImage.supported_modalities()
    end
  end

  describe "no key -> fast fail (no network)" do
    test "openai" do
      assert {:error, :missing_api_key} =
               OpenAIImage.generate_media(%Request{output: :image, prompt: "a cat"}, [])
    end

    test "gemini" do
      assert {:error, :missing_api_key} =
               GeminiImage.generate_media(%Request{output: :image, prompt: "a cat"}, [])
    end
  end

  describe "non-image output -> unsupported" do
    test "openai" do
      assert {:error, :unsupported_modality} =
               OpenAIImage.generate_media(%Request{output: :video, prompt: "x", api_key: "k"}, [])
    end
  end

  describe "happy path (Finch mocked)" do
    test "openai gpt-image-1 decodes b64_json -> bytes + mime" do
      stub(Finch, :request, fn _req, GenAI.Finch, _opts ->
        {:ok, %Finch.Response{status: 200, body: Jason.encode!(%{data: [%{b64_json: @png_b64}]})}}
      end)

      assert {:ok, %{data: @png, mime: "image/png", meta: %{}}} =
               OpenAIImage.generate_media(%Request{output: :image, prompt: "a cat", api_key: "sk-x"}, [])
    end

    test "gemini imagen decodes bytesBase64Encoded -> bytes + mime" do
      stub(Finch, :request, fn _req, GenAI.Finch, _opts ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: Jason.encode!(%{predictions: [%{bytesBase64Encoded: @png_b64}]})
         }}
      end)

      assert {:ok, %{data: @png, mime: "image/png", meta: %{}}} =
               GeminiImage.generate_media(%Request{output: :image, prompt: "a cat", api_key: "gm-x"}, [])
    end

    test "non-200 surfaces http_error" do
      stub(Finch, :request, fn _req, GenAI.Finch, _opts ->
        {:ok, %Finch.Response{status: 401, body: ~s({"error":"bad key"})}}
      end)

      assert {:error, {:http_error, 401, _}} =
               OpenAIImage.generate_media(%Request{output: :image, prompt: "x", api_key: "sk-x"}, [])
    end
  end
end
