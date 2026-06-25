defmodule GenAI.Provider.OpenAI.Speech do
  @moduledoc """
  OpenAI text-to-speech provider — a SYNC media provider (ADR-016).

  Declares `text -> speech` (sync) and runs `POST /v1/audio/speech`, returning the raw
  audio bytes (default mp3) in the shared `{:ok, %{data, mime, meta}}` contract. Voice +
  format come from `req.settings[:voice]` / `[:format]`; model defaults to gpt-4o-mini-tts.
  No-key requests fast-fail with `{:error, :missing_api_key}`.
  """
  @base_url "https://api.openai.com"
  @config_key :openai_speech
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H
  alias GenAI.Provider.Media.OpenAICompat

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities, do: [%{input: [:text], output: :speech, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: :speech} = req, _options) do
    with {:ok, key} <- H.require_key(req, "OPENAI_API_KEY") do
      OpenAICompat.speech(@base_url, key, req)
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}
end
