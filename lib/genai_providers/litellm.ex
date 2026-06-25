defmodule GenAI.Provider.LiteLLM do
  @moduledoc """
  Module for interacting with a LiteLLM proxy.

  LiteLLM is a self-hosted, OpenAI-compatible proxy/gateway in front of many upstream
  providers, so it reuses the standard behaviour/encoder machinery. Its `base_url` is
  deployment-specific — set `config :genai, :litellm, base_url: "...", api_key: "..."`
  (defaults to `http://localhost:4000`). Auth is a Bearer "virtual key".

  Media generation (image / speech / transcription / music / sfx / video) is handled by
  `GenAI.Provider.LiteLLM.Media`.
  """
  @base_url "http://localhost:4000"
  @config_key :litellm
  use GenAI.InferenceProviderBehaviour

  @doc "Runtime base_url from `config :genai, :litellm, base_url:` (defaults to localhost:4000)."
  def base_url, do: GenAI.Provider.MediaHelpers.base_url(:litellm, @base_url)

  @doc """
  Retrieves a list of models the LiteLLM proxy exposes.
  """
  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{base_url()}/v1/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{data: models, object: "list"} <- json do
        {:ok, Enum.map(models, &model_from_json/1)}
      else
        _ -> {:error, {:response, json}}
      end
    end
  end

  defp model_from_json(json) do
    %GenAI.Model{
      model: json[:id],
      provider: __MODULE__,
      details: json
    }
  end
end
