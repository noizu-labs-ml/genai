defmodule GenAI.Provider.Cerebras.Models do
  @base_url "https://api.cerebras.ai"
  import GenAI.InferenceProvider.Helpers

  # ⟦𓈗𓂓𓁞𓂟⟧ load_metadata :: auto-generated pointer for public function load_metadata
  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  # ⟦𓉡𓄰𓆚𓇓⟧ list :: auto-generated pointer for public function list
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

  # ⟦𓆡𓇏𓈨𓂿⟧ model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Cerebras,
      encoder: GenAI.Provider.Cerebras.Encoder
    }
  end

  # Cerebras-hosted models — verified live against /v1/models (2026-06-25).
  # ⟦𓈘𓋍𓌑𓍒⟧ gpt_oss_120b :: auto-generated pointer for public function gpt_oss_120b
  def gpt_oss_120b(), do: model("gpt-oss-120b")
  # ⟦𓊄𓍂𓅱𓁮⟧ zai_glm_4_7 :: auto-generated pointer for public function zai_glm_4_7
  def zai_glm_4_7(), do: model("zai-glm-4.7")

  # =============================================
  # Private Methods
  # =============================================
  defp model_metadata_provider do
    Application.get_env(:genai, :cerebras, [])[:metadata_provider] ||
      GenAI.ModelMetadata.DefaultProvider
  end

  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        model_metadata_provider(),
        GenAI.Provider.Cerebras,
        json[:id]
      )

    entry
  end
end
