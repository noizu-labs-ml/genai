defmodule GenAI.Provider.Qwen.Image do
  @moduledoc """
  Qwen Image 3.0 (DashScope multimodal-generation) — sync text/image -> image.

  Auth: request `api_key`, else `DASHSCOPE_API_KEY` / `QWEN_API_KEY` / `QWEN_TOKEN_KEY`.
  `settings[:plan] => :token_plan` uses the Singapore token-plan host.
  """
  @config_key :qwen_image
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H
  alias GenAI.Provider.Qwen.DashScope

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities, do: [%{input: [:text], output: :image, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: :image} = req, _options) do
    with {:ok, key} <- DashScope.require_key(req) do
      body = %{
        model: req.model || "qwen-image-3.0",
        input: %{
          messages: [
            %{
              role: "user",
              content: [%{text: H.prompt_text(req.prompt)}]
            }
          ]
        },
        parameters:
          %{}
          |> maybe(:negative_prompt, req.settings[:negative_prompt])
          |> maybe(:size, size(req))
          |> maybe(:n, req.settings[:n])
      }

      url = DashScope.multimodal_url(req)

      case H.post_json(url, key, body, receive_timeout: 180_000) do
        {:ok, %Finch.Response{status: status, body: resp}} when status in 200..299 ->
          with {:ok, image_url} <- image_url(resp),
               {:ok, bytes} <- H.download(image_url) do
            {:ok, %{data: bytes, mime: "image/png", meta: %{url: image_url}}}
          end

        {:ok, %Finch.Response{status: status, body: resp}} ->
          {:error, {:http_error, status, resp}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}

  defp image_url(resp) do
    with {:ok, json} <- Jason.decode(resp),
         url when is_binary(url) <-
           get_in(json, [
             "output",
             "choices",
             Access.at(0),
             "message",
             "content",
             Access.at(0),
             "image"
           ]) do
      {:ok, url}
    else
      _ -> {:error, :unexpected_response}
    end
  end

  defp size(req) do
    cond do
      is_binary(req.settings[:size]) ->
        String.replace(req.settings[:size], "x", "*")

      req.settings[:aspect_ratio] in ["1:1", "16:9", "9:16"] ->
        %{
          "1:1" => "1024*1024",
          "16:9" => "1280*720",
          "9:16" => "720*1280"
        }[req.settings[:aspect_ratio]]

      true ->
        nil
    end
  end

  defp maybe(map, _k, nil), do: map
  defp maybe(map, k, v), do: Map.put(map, k, v)
end
