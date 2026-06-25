defmodule GenAI.Provider.ZAI do
  @moduledoc """
  Module for interacting with the Z.AI (Zhipu GLM) API.

  Z.AI exposes an OpenAI-compatible chat-completions API under `/api/paas/v4`, so it reuses
  the standard behaviour/encoder machinery (Bearer auth from `config :genai, :zai, api_key:`).
  The chat endpoint path differs from the OpenAI default (`/chat/completions`, not
  `/v1/chat/completions`) and is overridden in `GenAI.Provider.ZAI.Encoder`.
  """
  @base_url "https://api.z.ai/api/paas/v4"
  @config_key :zai
  use GenAI.InferenceProviderBehaviour

  @doc """
  Retrieves a list of models supported by the Z.AI API for the given user.
  """
  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{@base_url}/models", headers)

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
