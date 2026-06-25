defmodule GenAI.Provider.OpenAI.Transcription do
  @moduledoc """
  OpenAI speech-to-text (transcription) provider — a SYNC media provider (ADR-016).

  Declares `speech -> text` (sync) and runs `POST /v1/audio/transcriptions` (multipart),
  returning the transcript in the shared `{:ok, %{data, mime, meta}}` contract (data = the
  text). The audio bytes ride in `req.settings[:audio]` (+ optional `:filename`,
  `:language`, `:hint`); model defaults to whisper-1. No-key -> `{:error, :missing_api_key}`,
  no audio -> `{:error, :missing_audio}`.

  Routing note: callers set `input: [:speech]` on the request (the audio is in settings,
  not the prompt) so the Router selects this provider.
  """
  @base_url "https://api.openai.com"
  @config_key :openai_transcription
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H
  alias GenAI.Provider.Media.OpenAICompat

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities, do: [%{input: [:speech], output: :text, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: :text} = req, _options) do
    with {:ok, key} <- H.require_key(req, "OPENAI_API_KEY") do
      OpenAICompat.transcription(@base_url, key, req)
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}
end
