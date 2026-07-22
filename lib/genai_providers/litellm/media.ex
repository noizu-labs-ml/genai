defmodule GenAI.Provider.LiteLLM.Media do
  @moduledoc """
  LiteLLM media-generation provider (ADR-016) — the proxy can host many media model types,
  so this declares the full set and dispatches by output modality:

    * `:image`          -> POST `/v1/images/generations` (b64_json)            [concrete]
    * `:speech` (TTS)   -> POST `/v1/audio/speech` (raw audio bytes)           [concrete]
    * `:text` (STT)     -> POST `/v1/audio/transcriptions` (multipart)         [concrete]
    * `:music`/`:sfx`/`:video` -> a deployment-configured passthrough endpoint [config]

  image/speech/transcription reuse the shared `OpenAICompat` calls. music/sfx/video have no
  universal OpenAI-compatible endpoint, so they route to a per-modality path from
  `config :genai, :litellm, media_endpoints: %{music: "/v1/...", video: "/v1/..."}` (or
  `req.settings[:endpoint]`); response is decoded as JSON-b64/url or raw bytes. Unconfigured
  -> `{:error, {:modality_not_configured, modality}}`.

  base_url + Bearer key come from `config :genai, :litellm` (or `LITELLM_API_KEY`).
  """
  @default_base_url "http://localhost:4000"
  @config_key :litellm
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H
  alias GenAI.Provider.Media.OpenAICompat

  @impl GenAI.InferenceProviderBehaviour
  # ⟦𓇌𓃫𓁽𓁕⟧ supported_modalities :: auto-generated pointer for public function supported_modalities
  def supported_modalities do
    [
      %{input: [:text], output: :image, mode: :sync},
      %{input: [:text], output: :speech, mode: :sync},
      %{input: [:text], output: :music, mode: :sync},
      %{input: [:text], output: :sfx, mode: :sync},
      %{input: [:text], output: :video, mode: :sync},
      %{input: [:speech], output: :text, mode: :sync}
    ]
  end

  @impl GenAI.InferenceProviderBehaviour
  # ⟦𓍨𓇏𓂱𓀷⟧ generate_media :: auto-generated pointer for public function generate_media
  def generate_media(%Request{output: out} = req, options) do
    with {:ok, key} <- H.require_key(req, "LITELLM_API_KEY") do
      base = H.base_url(:litellm, @default_base_url)
      dispatch(out, base, key, req, options)
    end
  end

  defp dispatch(:image, base, key, req, _), do: OpenAICompat.image(base, key, req)
  defp dispatch(:speech, base, key, req, _), do: OpenAICompat.speech(base, key, req)
  defp dispatch(:text, base, key, req, _), do: OpenAICompat.transcription(base, key, req)

  defp dispatch(out, base, key, req, _) when out in [:music, :sfx, :video] do
    case endpoint_for(out, req) do
      nil ->
        {:error, {:modality_not_configured, out}}

      path ->
        body =
          %{model: req.model, prompt: H.prompt_text(req.prompt)}
          |> Map.merge(req.settings[:body] || %{})

        (base <> path)
        |> H.post_json(key, body)
        |> decode_generation()
    end
  end

  defp dispatch(out, _base, _key, _req, _), do: {:error, {:unsupported_modality, out}}

  defp endpoint_for(out, req) do
    configured = :genai |> Application.get_env(:litellm, []) |> Keyword.get(:media_endpoints, %{})
    req.settings[:endpoint] || Map.get(configured, out)
  end

  # A passthrough response can be JSON (b64_json or a url) or raw bytes — handle both.
  defp decode_generation({:ok, %Finch.Response{status: 200, body: resp}}) do
    case Jason.decode(resp) do
      {:ok, json} -> decode_json_media(json)
      _ -> H.binary_result(resp, "application/octet-stream")
    end
  end

  defp decode_generation({:ok, %Finch.Response{status: status, body: resp}}),
    do: {:error, {:http_error, status, resp}}

  defp decode_generation({:error, reason}), do: {:error, {:request_failed, reason}}

  defp decode_json_media(json) do
    cond do
      b64 = get_in(json, ["data", H.access0(), "b64_json"]) ->
        case Base.decode64(b64) do
          {:ok, bytes} -> {:ok, %{data: bytes, mime: "application/octet-stream", meta: json}}
          _ -> {:error, :unexpected_response}
        end

      url = get_in(json, ["data", H.access0(), "url"]) ->
        {:ok, %{data: url, mime: "text/uri-list", meta: json}}

      true ->
        {:error, {:unexpected_response, json}}
    end
  end
end
