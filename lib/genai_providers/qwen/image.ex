defmodule GenAI.Provider.Qwen.Image do
  @moduledoc """
  Qwen Image 3.0 (DashScope multimodal-generation) — sync text/image -> image.

  Text-only prompts and reference-image edits both ride the multimodal route:
  up to 3 reference images are sent as base64 data-URL content parts followed by
  a single text part (ported from media-tools' proven Rust body,
  `src/providers/qwen_image.rs`). The route is synchronous-only on our accounts
  (the `X-DashScope-Async` header answers 403 AccessDenied) and sits behind a
  ~61s server-side connection close, so transport-level connection drops are
  retried over HTTP/1.1 (the `GenAI.Finch` default pool protocol).

  Auth: request `api_key`, else `DASHSCOPE_API_KEY` / `QWEN_API_KEY` / `QWEN_TOKEN_KEY`.
  `settings[:plan] => :token_plan` uses the Singapore token-plan host.
  """
  @config_key :qwen_image
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Message.Content.ImageContent
  alias GenAI.Message.Content.TextContent
  alias GenAI.Provider.MediaHelpers, as: H
  alias GenAI.Provider.Qwen.DashScope

  @max_attachments 3
  @connection_retries 3
  @receive_timeout 360_000

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities, do: [%{input: [:text, :image], output: :image, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: :image} = req, _options) do
    with {:ok, key} <- DashScope.require_key(req),
         {:ok, content} <- content_parts(req.prompt) do
      body = %{
        model: req.model || "qwen-image-3.0",
        input: %{messages: [%{role: "user", content: content}]},
        parameters:
          %{}
          |> maybe(:negative_prompt, req.settings[:negative_prompt])
          |> maybe(:size, size(req))
          |> maybe(:n, req.settings[:n])
      }

      url = DashScope.multimodal_url(req)
      post_with_retry(url, key, body, @connection_retries)
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}

  # --- content encoding (images first, text last; <=3 reference images) ------

  defp content_parts(prompt) when is_binary(prompt), do: {:ok, [%{text: prompt}]}

  defp content_parts(parts) when is_list(parts) do
    {images, texts} = Enum.split_with(parts, &image_part?/1)

    with {:ok, image_parts} <- encode_images(Enum.take(images, @max_attachments)) do
      text =
        texts
        |> Enum.map(&text_of/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.join(" ")

      {:ok, image_parts ++ [%{text: text}]}
    end
  end

  defp content_parts(_), do: {:ok, [%{text: ""}]}

  defp image_part?(%ImageContent{}), do: true
  defp image_part?(_), do: false

  defp text_of(%TextContent{text: t}) when is_binary(t), do: t
  defp text_of(t) when is_binary(t), do: t
  defp text_of(_), do: ""

  defp encode_images(images) do
    Enum.reduce_while(images, {:ok, []}, fn image, {:ok, acc} ->
      case data_url(image) do
        {:ok, url} -> {:cont, {:ok, acc ++ [%{image: url}]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  # Resource is canonical: {:base64, b64} (files are pre-encoded by ImageContent.new/2)
  # or {:uri, url} (downloaded then base64-encoded, faithful to the Rust data-URL body).
  defp data_url(%ImageContent{resource: {:base64, b64}} = image) when is_binary(b64),
    do: {:ok, "data:#{mime(image)};base64,#{b64}"}

  defp data_url(%ImageContent{resource: {:uri, url}} = image) when is_binary(url) do
    with {:ok, bytes} <- H.download(url) do
      {:ok, "data:#{mime(image)};base64,#{Base.encode64(bytes)}"}
    end
  end

  defp data_url(%ImageContent{source: {:file, path}} = image) when is_binary(path) do
    case File.read(path) do
      {:ok, bytes} -> {:ok, "data:#{mime(image)};base64,#{Base.encode64(bytes)}"}
      {:error, reason} -> {:error, {:image_read_failed, reason}}
    end
  end

  defp data_url(%ImageContent{}), do: {:error, :unsupported_image_resource}

  defp mime(%ImageContent{type: type}) when is_atom(type) and not is_nil(type),
    do: "image/#{type}"

  defp mime(%ImageContent{}), do: "image/png"

  # --- transport (sync, retry connection drops) ------------------------------

  defp post_with_retry(url, key, body, retries) do
    case H.post_json(url, key, body, receive_timeout: @receive_timeout) do
      {:ok, %Finch.Response{status: status, body: resp}} when status in 200..299 ->
        with {:ok, image_url} <- image_url(resp),
             {:ok, bytes} <- H.download(image_url) do
          {:ok, %{data: bytes, mime: "image/png", meta: %{url: image_url}}}
        end

      {:ok, %Finch.Response{status: status, body: resp}} ->
        {:error, {:http_error, status, resp}}

      {:error, %Finch.Error{}} when retries > 0 ->
        post_with_retry(url, key, body, retries - 1)

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  # Both the synchronous multimodal payload and async task-result shapes.
  defp url_paths do
    [
      ["output", "choices", Access.at(0), "message", "content", Access.at(0), "image"],
      ["output", "results", Access.at(0), "url"],
      ["output", "results", Access.at(0), "image"],
      ["output", "task_result", "results", Access.at(0), "url"],
      ["output", "url"]
    ]
  end

  defp image_url(resp) do
    with {:ok, json} <- Jason.decode(resp) do
      Enum.find_value(url_paths(), {:error, :unexpected_response}, fn path ->
        case get_in(json, path) do
          url when is_binary(url) -> {:ok, url}
          _ -> nil
        end
      end)
    else
      _ -> {:error, :unexpected_response}
    end
  end

  defp size(req) do
    cond do
      is_binary(req.settings[:size]) ->
        String.replace(req.settings[:size], "x", "*")

      not is_nil(req.settings[:aspect_ratio]) ->
        aspect_size(to_string(req.settings[:aspect_ratio]))

      true ->
        nil
    end
  end

  defp aspect_size("1:1"), do: "1024*1024"
  defp aspect_size("16:9"), do: "1280*720"
  defp aspect_size("9:16"), do: "720*1280"
  defp aspect_size("4:3"), do: "1024*768"
  defp aspect_size("3:4"), do: "768*1024"
  defp aspect_size(_), do: "1024*1024"

  defp maybe(map, _k, nil), do: map
  defp maybe(map, k, v), do: Map.put(map, k, v)
end