defmodule GenAI.Provider.OpenAI.Image do
  @moduledoc """
  OpenAI image-generation provider (gpt-image-1) — a SYNC media provider (ADR-016 / ede43647).

  Declares `text -> image` (sync) and runs `POST /v1/images/generations`, returning the
  base64 image in the shared `{:ok, %{data, mime, meta}}` contract. No-key requests fast-fail
  with `{:error, :missing_api_key}` before any network call.

  Image-INPUT (image+text -> image edits) is the follow-up increment: that path introduces
  the per-provider `encoder_protocol` ImageContent clause (dmitri N1) reused by vision +
  edit; this module is the text->image cut.
  """
  @base_url "https://api.openai.com"
  @config_key :openai_image
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H
  alias GenAI.Provider.Media.OpenAICompat

  @impl GenAI.InferenceProviderBehaviour
  # ⟦𓂒𓐑𓌈𓇐⟧ supported_modalities :: auto-generated pointer for public function supported_modalities
  def supported_modalities, do: [%{input: [:text], output: :image, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  # ⟦𓉥𓐟𓍑𓁽⟧ generate_media :: auto-generated pointer for public function generate_media
  def generate_media(%Request{output: :image} = req, _options) do
    with {:ok, key} <- H.require_key(req, "OPENAI_API_KEY") do
      OpenAICompat.image(@base_url, key, req)
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}
end
