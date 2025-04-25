defmodule GenAI.Provider.Mistral do
  @moduledoc """
  This module implements the GenAI provider for Mistral AI.
  """
  @base_url "https://api.mistral.ai"
  use GenAI.InferenceProviderBehaviour,
  

  @doc """
  Retrieves a list of available Mistral models.

  This function calls the Mistral API to retrieve a list of models and returns them as a list of `GenAI.Model` structs.
  """
  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{@base_url}/v1/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      case json do
        %{data: models, object: "list"} ->
          models = models |> Enum.map(&model_from_json/1)
          {:ok, models}

        _ ->
          {:error, {:response, json}}
      end
    end
  end

  # Converts a JSON representation of a Mistral model to a `GenAI.Model` struct.
  defp model_from_json(json) do
    %GenAI.Model{
      model: json[:id],
      provider: __MODULE__,
      details: json
    }
  end
end
