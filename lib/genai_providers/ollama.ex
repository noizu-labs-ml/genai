defmodule GenAI.Provider.Ollama do
  @moduledoc """
  Module for interacting with the Ollama API.
  Ollama provides local LLM inference with various open-source models.
  """
  @base_url "http://localhost:11434"
  @config_key :ollama
  use GenAI.InferenceProviderBehaviour

  # ------------------
  # models/0
  # models/1
  # ------------------
  @doc """
  Retrieves a list of models available on the local Ollama instance.
  """
  def models(settings \\ []) do
    headers = headers(settings)
    base_url = settings[:base_url] || @base_url
    call = api_call(:get, "#{base_url}/api/tags", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{models: models} <- json do
        models =
          models
          |> Enum.map(&model_from_json/1)

        {:ok, models}
      else
        _ -> {:error, {:response, json}}
      end
    end
  end

  defp model_from_json(json) do
    %GenAI.Model{
      model: json[:name],
      provider: __MODULE__,
      details: json
    }
  end
end