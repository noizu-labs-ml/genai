defmodule GenAI.Provider.LiteLLM.Models do
  @model_metadata_provider Application.compile_env(:genai, :litellm)[:metadata_provider] ||
                             GenAI.ModelMetadata.DefaultProvider

  import GenAI.InferenceProvider.Helpers

  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # LiteLLM proxies arbitrary upstream models under deployment-defined names — there are no
  # fixed presets. Use `model/1` with the name your proxy exposes, or `list/1` to enumerate.
  def list(options \\ nil) do
    headers = GenAI.Provider.LiteLLM.headers(options)
    call = api_call(:get, "#{GenAI.Provider.LiteLLM.base_url()}/v1/models", headers)

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
      provider: GenAI.Provider.LiteLLM,
      encoder: GenAI.Provider.LiteLLM.Encoder
    }
  end

  # =============================================
  # Private Methods
  # =============================================
  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        @model_metadata_provider,
        GenAI.Provider.LiteLLM,
        json[:id]
      )

    entry
  end
end
