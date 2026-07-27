defmodule GenAI.Provider.Media.OpenAICompat do
  @moduledoc """
  Shared OpenAI-compatible media-generation calls (ADR-016), parameterized by base_url +
  API key so the OpenAI providers and the LiteLLM proxy providers share ONE definition of
  each endpoint's request build + response decode (dmitri's "one definition" principle):

    * `image/3`         - POST `{base}/v1/images/generations`   -> b64_json image bytes
    * `speech/3`        - POST `{base}/v1/audio/speech`         -> raw audio bytes (TTS)
    * `transcription/3` - POST `{base}/v1/audio/transcriptions` (multipart) -> transcript (STT)
    * `audio_chat/3`    - POST `{base}/v1/chat/completions` with gpt-audio -> spoken reply

  Each returns the shared media contract `{:ok, %{data, mime, meta}}` | `{:error, term}`.
  """
  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H

  @doc "text -> image (gpt-image-1 / DALL·E compatible)."
  # ⟦𓃲𓌗𓊏𓁖⟧ image :: text -> image (gpt-image-1 / DALL·E compatible).
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
  # ⟦𓇾𓈀𓋵𓄎⟧ speech :: text -> speech (TTS); returns raw audio bytes with the right MIME.
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
  # ⟦𓊾𓄛𓈪𓈷⟧ transcription :: speech -> text (transcription).
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

  @doc "text/audio -> speech using OpenAI audio-capable chat completions."
  # ⟦𓎣𓁻𓏥𓈭⟧ audio_chat :: text/audio -> speech using OpenAI audio-capable chat completions.
  def audio_chat(base_url, key, %Request{} = req) do
    fmt = to_string(req.settings[:format] || "wav")

    body =
      %{
        model: req.model || "gpt-audio-1.5",
        modalities: ["text", "audio"],
        audio: %{
          voice: to_string(req.settings[:voice] || "alloy"),
          format: fmt
        },
        messages: audio_messages(req)
      }
      |> maybe_put_map(:store, req.settings[:store])
      |> maybe_put_map(:metadata, req.settings[:metadata])

    "#{base_url}/v1/chat/completions"
    |> H.post_json(key, body)
    |> handle(fn resp -> decode_audio_chat(resp, H.audio_mime(fmt)) end)
  end

  # ---- internals ----

  defp handle({:ok, %Finch.Response{status: 200, body: resp}}, on_200), do: on_200.(resp)

  defp handle({:ok, %Finch.Response{status: status, body: resp}}, _),
    do: {:error, {:http_error, status, resp}}

  defp handle({:error, reason}, _), do: {:error, {:request_failed, reason}}

  defp maybe_put(fields, _key, nil), do: fields
  defp maybe_put(fields, key, value), do: fields ++ [{key, to_string(value)}]

  defp maybe_put_map(map, _key, nil), do: map
  defp maybe_put_map(map, key, value), do: Map.put(map, key, value)

  defp audio_messages(%Request{settings: %{messages: messages}}) when is_list(messages),
    do: messages

  defp audio_messages(%Request{} = req) do
    user_content = audio_user_content(req)

    system_messages =
      case req.settings[:instructions] do
        nil -> []
        instructions -> [%{role: "system", content: to_string(instructions)}]
      end

    system_messages ++ [%{role: "user", content: user_content}]
  end

  defp audio_user_content(%Request{} = req) do
    text = H.prompt_text(req.prompt)

    case audio_input(req) do
      nil ->
        blank_to_default(text, "")

      %{data: data, format: format} ->
        [
          %{type: "text", text: blank_to_default(text, "Respond to this audio.")},
          %{type: "input_audio", input_audio: %{data: data, format: format}}
        ]
    end
  end

  defp audio_input(%Request{settings: settings, prompt: prompt}) do
    cond do
      is_binary(settings[:audio]) ->
        %{
          data: Base.encode64(settings[:audio]),
          format: input_audio_format(settings)
        }

      audio = audio_content(prompt) ->
        {:ok, encoded} = GenAI.Message.Content.AudioContent.base64(audio.resource, audio.options)
        %{data: encoded, format: to_string(audio.type || input_audio_format(settings))}

      true ->
        nil
    end
  end

  defp audio_content(parts) when is_list(parts) do
    Enum.find(parts, &match?(%GenAI.Message.Content.AudioContent{}, &1))
  end

  defp audio_content(_), do: nil

  defp input_audio_format(settings) do
    cond do
      settings[:input_format] ->
        to_string(settings[:input_format])

      settings[:filename] ->
        settings[:filename]
        |> Path.extname()
        |> String.trim_leading(".")
        |> blank_to_default("wav")

      true ->
        "wav"
    end
  end

  defp blank_to_default("", default), do: default
  defp blank_to_default(nil, default), do: default
  defp blank_to_default(value, _default), do: to_string(value)

  defp decode_audio_chat(body, mime) do
    with {:ok, json} <- Jason.decode(body),
         message when is_map(message) <- get_in(json, ["choices", H.access0(), "message"]),
         audio when is_map(audio) <- message["audio"],
         data when is_binary(data) <- audio["data"],
         {:ok, bytes} <- Base.decode64(data) do
      {:ok,
       %{
         data: bytes,
         mime: mime,
         meta: %{
           text: message["content"] || audio["transcript"],
           transcript: audio["transcript"],
           response: json
         }
       }}
    else
      _ -> {:error, :unexpected_response}
    end
  end
end
