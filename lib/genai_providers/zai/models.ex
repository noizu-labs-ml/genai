defmodule GenAI.Provider.ZAI.Models do
  @base_url "https://api.z.ai/api/paas/v4"
  @model_metadata_provider Application.compile_env(:genai, :zai)[:metadata_provider] ||
                             GenAI.ModelMetadata.DefaultProvider

  import GenAI.InferenceProvider.Helpers

  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  def list(options \\ nil) do
    headers = GenAI.Provider.ZAI.headers(options)
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

  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.ZAI,
      encoder: GenAI.Provider.ZAI.Encoder
    }
  end

  # GLM family (https://docs.z.ai/)
  def glm_4_6(), do: model("glm-4.6")
  def glm_4_5(), do: model("glm-4.5")
  def glm_4_5_x(), do: model("glm-4.5-x")
  def glm_4_5_air(), do: model("glm-4.5-air")
  def glm_4_5_airx(), do: model("glm-4.5-airx")
  def glm_4_5_flash(), do: model("glm-4.5-flash")
  def glm_4_5v(), do: model("glm-4.5v")
  def glm_4_32b(), do: model("glm-4-32b-0414-128k")

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
