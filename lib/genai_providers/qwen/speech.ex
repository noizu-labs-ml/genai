defmodule GenAI.Provider.Qwen.Speech do
  @moduledoc """
  Qwen TTS (DashScope multimodal-generation) — sync text -> speech.

  Default model `qwen3-tts-flash`. Auth same as other Qwen media providers.
  """
  @config_key :qwen_speech
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H
  alias GenAI.Provider.Qwen.DashScope

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities, do: [%{input: [:text], output: :speech, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: :speech} = req, _options) do
    with {:ok, key} <- DashScope.require_key(req) do
      body = %{
        model: req.model || "qwen3-tts-flash",
        input: %{
          text: H.prompt_text(req.prompt),
          voice: to_string(req.settings[:voice] || "Cherry"),
          language_type: to_string(req.settings[:language] || "English")
        }
      }

      case H.post_json(DashScope.multimodal_url(req), key, body, receive_timeout: 120_000) do
        {:ok, %Finch.Response{status: status, body: resp}} when status in 200..299 ->
          with {:ok, audio_url} <- audio_url(resp),
               {:ok, bytes} <- H.download(audio_url) do
            {:ok, %{data: bytes, mime: "audio/mpeg", meta: %{url: audio_url}}}
          end

        {:ok, %Finch.Response{status: status, body: resp}} ->
          {:error, {:http_error, status, resp}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}

  defp audio_url(resp) do
    with {:ok, json} <- Jason.decode(resp),
         url when is_binary(url) <- get_in(json, ["output", "audio", "url"]) do
      {:ok, url}
    else
      _ -> {:error, :unexpected_response}
    end
  end
end
