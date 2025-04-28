defmodule GenAI.Provider.XAI.Models do
  @base_url "https://api.x.ai"
  @model_metadata_provider (Application.compile_env(:genai, :xai)[:metadata_provider] || GenAI.ModelMetadata.DefaultProvider)

  import GenAI.InferenceProvider.Helpers
  
  def load_metadata(options \\ nil)
  def load_metadata(_) do
    :ok
  end
  
  # TODO allow local meta data merge
  def list(options \\ nil) do
    headers = GenAI.Provider.XAI.headers(options)
    call = api_call(:get, "#{@base_url}/v1/models", headers)
    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do

      with %{data: models, object: "list"} <- json do
        models = models
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
      provider: GenAI.Provider.XAI,
      encoder: GenAI.Provider.XAI.Encoder
    }
  end
  
  def grok_3(), do: model("grok-3")
  def grok_3_fast(), do: model("grok-3-fast")
  def grok_3_mini(), do: model("grok-3-mini")
  def grok_3_mini_fast(), do: model("grok-3-mini-fast")
  

  

  #=============================================
  # Private Methods
  #=============================================


  #------------------
  # Extract model from api request response.
  # @TODO move into Model module
  #------------------
  defp model_from_json(json) do
    {:ok, entry} = GenAI.ModelMetadata.ProviderBehaviour.get(@model_metadata_provider, GenAI.Provider.XAI, json[:id])
    entry
  end


end
