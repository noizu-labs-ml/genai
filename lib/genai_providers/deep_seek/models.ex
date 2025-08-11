defmodule GenAI.Provider.DeepSeek.Models do
  @base_url "https://api.deepseek.com"
  @model_metadata_provider Application.compile_env(:genai, :openai)[:metadata_provider] ||
                             GenAI.ModelMetadata.DefaultProvider

  import GenAI.InferenceProvider.Helpers

  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  def list(options \\ nil) do
    headers = GenAI.Provider.DeepSeek.headers(options)
    call = api_call(:get, "#{@base_url}/models", headers)

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
      provider: GenAI.Provider.DeepSeek,
      encoder: GenAI.Provider.DeepSeek.Encoder
    }
  end

  def deepseek_chat(), do: model("deepseek-chat")
  def deepseek_reasoner(), do: model("deepseek-reasoner")

  # =============================================
  # Private Methods
  # =============================================


  # ------------------
  # Extract model from api request response.
  # @TODO move into Model module
  # ------------------
  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        @model_metadata_provider,
        GenAI.Provider.DeepSeek,
        json[:id]
      )

    entry
  end
end
