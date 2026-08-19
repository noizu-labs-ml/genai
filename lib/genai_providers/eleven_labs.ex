defmodule GenAI.Provider.ElevenLabs do
  @moduledoc """
  ElevenLabs audio media provider (ADR-016). NOT an LLM — media only.

  Official API (https://api.elevenlabs.io). All three capabilities are SYNC endpoints that
  return audio bytes directly (no job/polling), so every declared modality is `:sync` and
  `generate_media/2` returns the shared `{:ok, %{data, mime, meta}}` contract:

    * speech - `POST /v1/text-to-speech/{voice_id}` (model `eleven_multilingual_v2`, output
      format `mp3_44100_128`; voice defaults to Rachel and comes from
      `req.settings[:voice_id]` / `[:voice]`)
    * sfx    - `POST /v1/sound-generation` (`duration_seconds`, `prompt_influence` knobs;
      always `audio/mpeg`)
    * music  - `POST /v1/music/compose` (model `music_v1` default — pass `"music_v2"`
      explicitly for the current generation; `music_length_ms`, `force_instrumental`)

  Auth is the `xi-api-key` header (NOT Bearer). Key resolution: `req.api_key` first, then
  `ELEVENLABS_API_KEY`; missing keys fast-fail `{:error, :missing_api_key}`. base_url is
  overridable via `config :genai, :eleven_labs, base_url: "..."`.
  """
  @default_base_url "https://api.elevenlabs.io"
  @default_voice_id "21m00Tcm4TlvDq8ikWAM"
  @config_key :eleven_labs
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H

  @impl GenAI.InferenceProviderBehaviour
  # ⟦𓄸𓎾𓏦𓎱⟧ supported_modalities :: auto-generated pointer for public function supported_modalities
  def supported_modalities do
    [
      %{input: [:text], output: :speech, mode: :sync},
      %{input: [:text], output: :sfx, mode: :sync},
      %{input: [:text], output: :music, mode: :sync}
    ]
  end

  @impl GenAI.InferenceProviderBehaviour
  # ⟦𓂋𓃭𓈖𓈁⟧ generate_media :: auto-generated pointer for public function generate_media
  def generate_media(%Request{output: :speech} = req, _options),
    do: with_key(req, &tts(&1, &2))

  def generate_media(%Request{output: :sfx} = req, _options),
    do: with_key(req, &sfx(&1, &2))

  def generate_media(%Request{output: :music} = req, _options),
    do: with_key(req, &music(&1, &2))

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}

  # ---- capabilities ----

  defp with_key(req, fun) do
    with {:ok, key} <- H.require_key(req, "ELEVENLABS_API_KEY"), do: fun.(req, key)
  end

  # text -> speech: POST /v1/text-to-speech/{voice_id}?output_format=mp3_44100_128
  defp tts(req, key) do
    voice_id = to_string(req.settings[:voice_id] || req.settings[:voice] || @default_voice_id)
    format = to_string(req.settings[:format] || "mp3_44100_128")

    body =
      %{text: H.prompt_text(req.prompt), model_id: req.model || "eleven_multilingual_v2"}
      |> maybe_put_map(:voice_settings, voice_settings(req))

    url = "#{base()}/v1/text-to-speech/#{voice_id}?output_format=#{format}"
    post(url, key, body, output_mime(format))
  end

  # text -> sfx: POST /v1/sound-generation (sync; 200 -> audio/mpeg bytes)
  defp sfx(req, key) do
    body =
      %{text: H.prompt_text(req.prompt)}
      |> maybe_put_map(:duration_seconds, req.settings[:duration_seconds])
      |> maybe_put_map(:prompt_influence, req.settings[:prompt_influence])

    post("#{base()}/v1/sound-generation", key, body, "audio/mpeg")
  end

  # text -> music: POST /v1/music/compose (sync; returns the generated audio file).
  # output_format "auto" lets ElevenLabs pick (mp3_44100_128 for music_v1, mp3_48000_192
  # for music_v2).
  defp music(req, key) do
    format = to_string(req.settings[:format] || "auto")

    body =
      %{prompt: H.prompt_text(req.prompt), model_id: req.model || "music_v1"}
      |> maybe_put_map(:music_length_ms, req.settings[:music_length_ms])
      |> maybe_put_map(:force_instrumental, req.settings[:force_instrumental])

    post("#{base()}/v1/music/compose?output_format=#{format}", key, body, output_mime(format))
  end

  # ---- internals ----

  defp base, do: H.base_url(:eleven_labs, @default_base_url)

  defp voice_settings(%Request{settings: settings}) do
    %{}
    |> maybe_put_map(:stability, settings[:stability])
    |> maybe_put_map(:similarity_boost, settings[:similarity_boost])
    |> maybe_put_map(:style, settings[:style])
    |> maybe_put_map(:use_speaker_boost, settings[:use_speaker_boost])
    |> maybe_put_map(:speed, settings[:speed])
    |> case do
      vs when map_size(vs) == 0 -> nil
      vs -> vs
    end
  end

  # xi-api-key auth (not Bearer) — ElevenLabs' own header scheme, so this is local to the
  # provider rather than a MediaHelpers post_json variant.
  defp post(url, key, body, mime) do
    with {:ok, json} <- Jason.encode(body) do
      headers = [{"xi-api-key", key}, {"content-type", "application/json"}, {"accept", mime}]

      Finch.build(:post, url, headers, json)
      |> Finch.request(GenAI.Finch, H.media_opts())
      |> case do
        {:ok, %Finch.Response{status: status, body: resp}} when status in 200..299 ->
          H.binary_result(resp, mime)

        {:ok, %Finch.Response{status: status, body: resp}} ->
          {:error, {:http_error, status, resp}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    end
  end

  defp maybe_put_map(map, _key, nil), do: map
  defp maybe_put_map(map, key, value), do: Map.put(map, key, value)

  # ElevenLabs output_format is codec_sample_rate_bitrate (e.g. mp3_44100_128); the codec
  # prefix maps to the MIME. "auto" and unknown codecs fall back to audio/mpeg.
  defp output_mime(format) do
    case to_string(format) |> String.split("_") |> hd() |> H.audio_mime() do
      "application/octet-stream" -> "audio/mpeg"
      mime -> mime
    end
  end
end
