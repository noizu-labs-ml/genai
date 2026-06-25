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

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities, do: [%{input: [:text], output: :image, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: :image} = req, _options) do
    with {:ok, key} <- H.require_key(req, "OPENAI_API_KEY") do
      body = %{
        model: req.model || "gpt-image-1",
        prompt: H.prompt_text(req.prompt),
        size: req.settings[:size] || "1024x1024",
        n: 1
      }

      headers = [{"authorization", "Bearer #{key}"}, {"content-type", "application/json"}]

      case api_call(:post, "#{@base_url}/v1/images/generations", headers, body) do
        {:ok, %Finch.Response{status: 200, body: resp}} ->
          H.decode_image(resp, ["data", H.access0(), "b64_json"])

        {:ok, %Finch.Response{status: status, body: resp}} ->
          {:error, {:http_error, status, resp}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}
end
