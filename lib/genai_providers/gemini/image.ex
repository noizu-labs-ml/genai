defmodule GenAI.Provider.Gemini.Image do
  @moduledoc """
  Gemini Imagen image-generation provider — a SYNC media provider (ADR-016 / ede43647).

  Declares `text -> image` (sync) and runs `POST /v1beta/models/{model}:predict` (the
  Imagen predict endpoint, API key as a query param), returning the base64 image in the
  shared `{:ok, %{data, mime, meta}}` contract. No-key requests fast-fail with
  `{:error, :missing_api_key}` before any network call.

  Image-INPUT (image+text -> image edits, the `:generateContent` inline_data path) is the
  follow-up increment that introduces the per-provider `encoder_protocol` ImageContent
  clause (dmitri N1) reused by vision + edit; this module is the text->image cut.
  """
  @base_url "https://generativelanguage.googleapis.com/v1beta/models"
  @default_model "imagen-4.0-generate-001"
  @config_key :gemini_image
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities, do: [%{input: [:text], output: :image, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: :image} = req, _options) do
    with {:ok, key} <- H.require_key(req, "GEMINI_API_KEY") do
      model = req.model || @default_model
      url = "#{@base_url}/#{model}:predict?key=#{key}"
      body = %{instances: [%{prompt: H.prompt_text(req.prompt)}], parameters: %{sampleCount: 1}}
      headers = [{"content-type", "application/json"}]

      case api_call(:post, url, headers, body) do
        {:ok, %Finch.Response{status: 200, body: resp}} ->
          H.decode_image(resp, ["predictions", H.access0(), "bytesBase64Encoded"])

        {:ok, %Finch.Response{status: status, body: resp}} ->
          {:error, {:http_error, status, resp}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}
end
