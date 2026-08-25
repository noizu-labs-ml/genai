defmodule GenAI.Provider.ZAI.Models do
  @base_url "https://api.z.ai/api/paas/v4"
  import GenAI.InferenceProvider.Helpers

  # ⟦𓍯𓌅𓃒𓂳⟧ load_metadata :: auto-generated pointer for public function load_metadata
  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  # ⟦𓆙𓄘𓈴𓊤⟧ list :: auto-generated pointer for public function list
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

  # ⟦𓅛𓀖𓀐𓈥⟧ model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.ZAI,
      encoder: GenAI.Provider.ZAI.Encoder
    }
  end

  # GLM family — verified live against /api/paas/v4/models (2026-06-25).

  # GLM-5.x (flagship)
  # ⟦𓆻𓅯𓏁𓅿⟧ glm_5_2 :: auto-generated pointer for public function glm_5_2
  def glm_5_2(), do: model("glm-5.2")
  # ⟦𓋘𓍣𓃗𓃤⟧ glm_5_1 :: auto-generated pointer for public function glm_5_1
  def glm_5_1(), do: model("glm-5.1")
  # ⟦𓀣𓆥𓁰𓂨⟧ glm_5_turbo :: auto-generated pointer for public function glm_5_turbo
  def glm_5_turbo(), do: model("glm-5-turbo")
  # ⟦𓉙𓁉𓌥𓃂⟧ glm_5 :: auto-generated pointer for public function glm_5
  def glm_5(), do: model("glm-5")

  # GLM-4.x
  # ⟦𓀟𓅃𓉫𓇞⟧ glm_4_7 :: auto-generated pointer for public function glm_4_7
  def glm_4_7(), do: model("glm-4.7")
  # ⟦𓏹𓉰𓌩𓂨⟧ glm_4_6 :: auto-generated pointer for public function glm_4_6
  def glm_4_6(), do: model("glm-4.6")
  # ⟦𓎉𓁓𓀖𓀺⟧ glm_4_5 :: auto-generated pointer for public function glm_4_5
  def glm_4_5(), do: model("glm-4.5")
  # ⟦𓅚𓅷𓁿𓅂⟧ glm_4_5_air :: auto-generated pointer for public function glm_4_5_air
  def glm_4_5_air(), do: model("glm-4.5-air")

  # =============================================
  # Private Methods
  # =============================================
  defp model_metadata_provider do
    Application.get_env(:genai, :zai, [])[:metadata_provider] ||
      GenAI.ModelMetadata.DefaultProvider
  end

  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        model_metadata_provider(),
        GenAI.Provider.ZAI,
        json[:id]
      )

    entry
  end
end
