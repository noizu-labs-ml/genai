defmodule GenAI.Provider.OpenAI do
  @moduledoc """
  Module for interacting with the OpenAI API.
  """
  @base_url "https://api.openai.com"
  @config_key :openai
  use GenAI.InferenceProviderBehaviour

  #------------------
  # models/0
  # models/1
  #------------------
  @doc """
  Retrieves a list of models supported by the OpenAI API for given user.
  """
  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{@base_url}/v1/models", headers)
    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do

      with %{data: models, object: "list"} <- json do
        models = models
                 |> Enum.map(&model_from_json/1)
        {:ok, models}
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
