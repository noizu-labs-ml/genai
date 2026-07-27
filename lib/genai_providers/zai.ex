defmodule GenAI.Provider.ZAI do
  @moduledoc """
  Module for interacting with the Z.AI API (GLM model family).
  """
  @base_url "https://api.z.ai"
  @config_key :zai
  use GenAI.InferenceProviderBehaviour

  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{@base_url}/api/paas/v4/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{data: models, object: "list"} <- json do
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
      model: json[:id],
      provider: __MODULE__,
      details: json
    }
  end
end
