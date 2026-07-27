defmodule GenAI.Provider.ZAI.Models do
  @base_url "https://api.z.ai"
  @model_metadata_provider Application.compile_env(:genai, :zai)[:metadata_provider] ||
                             GenAI.ModelMetadata.DefaultProvider

  import GenAI.InferenceProvider.Helpers

  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  def list(options \\ nil) do
    headers = GenAI.Provider.ZAI.headers(options)
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

  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.ZAI,
      encoder: GenAI.Provider.ZAI.Encoder
    }
  end

  def glm_5_1(), do: model("glm-5.1")
  def glm_5(), do: model("glm-5")
  def glm_4_7(), do: model("glm-4.7")
  def glm_4_5(), do: model("glm-4.5")
  def glm_4_5_air(), do: model("glm-4.5-air")

  # =============================================
  # Private Methods
  # =============================================

  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        @model_metadata_provider,
        GenAI.Provider.ZAI,
        json[:id]
      )

    entry
  end
end
