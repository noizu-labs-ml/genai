defmodule GenAI.Provider.Gemini do
  @moduledoc """
  This module implements the GenAI provider for Mistral AI.
  """
  @base_url "https://generativelanguage.googleapis.com"
  use GenAI.InferenceProviderBehaviour
  
  
  defp expand_settings(settings) do
    config_settings = Application.get_env(:genai, config_key(), [])
    %{settings: settings, config_settings: config_settings}
  end

  @doc """
  Retrieves a list of available Mistral models.

  This function calls the Mistral API to retrieve a list of models and returns them as a list of `GenAI.Model` structs.
  """
  def models(settings \\ []) do
    headers = headers(settings)
    settings = expand_settings(settings)
    
    {:ok, api_key} = GenAI.Provider.Gemini.Encoder.api_key(settings)
    url = "#{@base_url}/v1beta/models?key=#{api_key}"
    
    call = api_call(:get, url, headers)
    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{models: models} <- json do
        models = Enum.map(models, &model_from_json/1)
        {:ok, models}
      end
    end
  end

  # Converts a JSON representation of a Mistral model to a `GenAI.Model` struct.
  defp model_from_json( %{name: "models/" <> model_name} = json) do
    %GenAI.Model{
      model: model_name,
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder,
      details: json
    }
  end
  
end
