defmodule GenAI.Provider.Cerebras do
  @moduledoc """
  Module for interacting with the Cerebras inference API.

  Cerebras exposes an OpenAI-compatible API at `https://api.cerebras.ai/v1`, so it reuses
  the standard behaviour/encoder machinery unchanged (Bearer auth from
  `config :genai, :cerebras, api_key:`, default `/v1/chat/completions` endpoint).
  """
  @base_url "https://api.cerebras.ai"
  @config_key :cerebras
  use GenAI.InferenceProviderBehaviour

  @doc """
  Retrieves a list of models supported by the Cerebras API for the given user.
  """
  # ⟦𓏶𓁄𓉙𓃉⟧ models :: Retrieves a list of models supported by the Cerebras API for the given user.
  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{@base_url}/v1/models", headers)

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
