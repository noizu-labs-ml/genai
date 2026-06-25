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

  # Cerebras-hosted models (https://inference-docs.cerebras.ai/)
  def llama_3_3_70b(), do: model("llama-3.3-70b")
  def llama_3_1_8b(), do: model("llama3.1-8b")
  def llama_4_scout_17b(), do: model("llama-4-scout-17b-16e-instruct")
  def llama_4_maverick_17b(), do: model("llama-4-maverick-17b-128e-instruct")
  def qwen_3_32b(), do: model("qwen-3-32b")
  def qwen_3_235b(), do: model("qwen-3-235b-a22b-instruct-2507")
  def gpt_oss_120b(), do: model("gpt-oss-120b")

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
