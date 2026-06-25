defmodule GenAI.Provider.Media.OpenAICompat do
  @moduledoc """
  Shared OpenAI-compatible media-generation calls (ADR-016), parameterized by base_url +
  API key so the OpenAI providers and the LiteLLM proxy providers share ONE definition of
  each endpoint's request build + response decode (dmitri's "one definition" principle):

    * `image/3`         - POST `{base}/v1/images/generations`   -> b64_json image bytes
    * `speech/3`        - POST `{base}/v1/audio/speech`         -> raw audio bytes (TTS)
    * `transcription/3` - POST `{base}/v1/audio/transcriptions` (multipart) -> transcript (STT)

  Each returns the shared media contract `{:ok, %{data, mime, meta}}` | `{:error, term}`.
  """
  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H

  @doc "text -> image (gpt-image-1 / DALL·E compatible)."
  def image(base_url, key, %Request{} = req) do
    body = %{
      model: req.model || "gpt-image-2",
      prompt: H.prompt_text(req.prompt),
      size: to_string(req.settings[:size] || "1024x1024"),
      n: req.settings[:n] || 1
    }

    "#{base_url}/v1/images/generations"
    |> H.post_json(key, body)
    |> handle(fn resp -> H.decode_image(resp, ["data", H.access0(), "b64_json"]) end)
  end

  @doc "text -> speech (TTS); returns raw audio bytes with the right MIME."
  def speech(base_url, key, %Request{} = req) do
    fmt = to_string(req.settings[:format] || "mp3")

    body = %{
      model: req.model || "gpt-4o-mini-tts",
      input: H.prompt_text(req.prompt),
      voice: to_string(req.settings[:voice] || "alloy"),
      response_format: fmt
    }

    "#{base_url}/v1/audio/speech"
    |> H.post_json(key, body)
    |> handle(fn resp -> H.binary_result(resp, H.audio_mime(fmt)) end)
  end

  @doc "speech -> text (transcription). Audio bytes ride in `req.settings[:audio]`."
  def transcription(base_url, key, %Request{} = req) do
    case req.settings[:audio] do
      audio when is_binary(audio) ->
        filename = to_string(req.settings[:filename] || "audio.mp3")
        ctype = H.audio_mime(filename |> Path.extname() |> String.trim_leading("."))

        fields =
          [model: req.model || "gpt-4o-transcribe"]
          |> maybe_put(:language, req.settings[:language])
          |> maybe_put(:prompt, req.settings[:hint])

        {content_type, mp_body} = H.multipart(fields, {"file", filename, audio, ctype})
        headers = [{"authorization", "Bearer #{key}"}, {"content-type", content_type}]

        "#{base_url}/v1/audio/transcriptions"
        |> H.raw_post(headers, mp_body)
        |> handle(fn resp -> H.decode_text(resp, ["text"]) end)

      _ ->
        {:error, :missing_audio}
    end
  end

  # ---- internals ----

  defp handle({:ok, %Finch.Response{status: 200, body: resp}}, on_200), do: on_200.(resp)
  defp handle({:ok, %Finch.Response{status: status, body: resp}}, _), do: {:error, {:http_error, status, resp}}
  defp handle({:error, reason}, _), do: {:error, {:request_failed, reason}}

  defp maybe_put(fields, _key, nil), do: fields
  defp maybe_put(fields, key, value), do: fields ++ [{key, to_string(value)}]
end
