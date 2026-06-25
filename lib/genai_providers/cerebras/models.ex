defmodule GenAI.Provider.Cerebras.Models do
  @base_url "https://api.cerebras.ai"
  @model_metadata_provider Application.compile_env(:genai, :cerebras)[:metadata_provider] ||
                             GenAI.ModelMetadata.DefaultProvider

  import GenAI.InferenceProvider.Helpers

  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  def list(options \\ nil) do
    headers = GenAI.Provider.Cerebras.headers(options)
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

  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Cerebras,
      encoder: GenAI.Provider.Cerebras.Encoder
    }
  end

  # Cerebras-hosted models — verified live against /v1/models (2026-06-25).
  def gpt_oss_120b(), do: model("gpt-oss-120b")
  def zai_glm_4_7(), do: model("zai-glm-4.7")

  # =============================================
  # Private Methods
  # =============================================
  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        @model_metadata_provider,
        GenAI.Provider.Cerebras,
        json[:id]
      )

    entry
  end
end
