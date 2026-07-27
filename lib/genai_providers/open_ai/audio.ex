defmodule GenAI.Provider.OpenAI.Audio do
  @moduledoc """
  OpenAI audio chat provider for spoken responses with current audio-capable models.

  This provider uses `POST /v1/chat/completions` with `gpt-audio-1.5` and
  `modalities: ["text", "audio"]`, so callers can generate speech from text or run a
  bounded speech-to-speech turn through the shared `GenAI.generate_media/2` media path.
  For live, low-latency voice sessions, use OpenAI Realtime outside this sync media
  contract.
  """
  @base_url "https://api.openai.com"
  @config_key :openai_audio
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.Media.OpenAICompat
  alias GenAI.Provider.MediaHelpers, as: H

  @impl GenAI.InferenceProviderBehaviour
  # ⟦𓎧𓇵𓌟𓏚⟧ supported_modalities :: auto-generated pointer for public function supported_modalities
  def supported_modalities, do: [%{input: [:text, :speech], output: :speech, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  # ⟦𓇺𓁹𓂔𓐅⟧ generate_media :: auto-generated pointer for public function generate_media
  def generate_media(%Request{output: :speech} = req, _options) do
    with {:ok, key} <- H.require_key(req, "OPENAI_API_KEY") do
      OpenAICompat.audio_chat(@base_url, key, req)
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}
end
