defmodule GenAI.Provider.OpenAI.Models do
  @api_base "https://api.openai.com"
  @model_metadata_provider (Application.compile_env(:genai, :openai)[:metadata_provider] || GenAI.ModelMetadata.DefaultProvider)

  import GenAI.InferenceProvider.Helpers
  
  def load_metadata(options \\ nil)
  def load_metadata(_) do
    :ok
  end
  
  # TODO allow local meta data merge
  def list(options \\ nil) do
    headers = GenAI.Provider.OpenAI.headers(options)
    call = api_call(:get, "#{@api_base}/v1/models", headers)
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
      provider: GenAI.Provider.OpenAI,
      encoder: GenAI.Provider.OpenAI.Encoder
    }
  end
  
  def gpt_3_5_turbo(), do: model("gpt-3.5-turbo")
  def gpt_3_5_turbo_16k(), do: model("gpt-3.5-turbo-16k")
  
  def gpt_4(), do: model("gpt-4")
  def gpt_4_turbo(), do: model("gpt-4-turbo")
  def gpt_4_vision(), do: model("gpt-4-vision")
  
  def gpt_4_1(), do: model("gpt-4.1")
  def gpt_4_1(), do: model("gpt-4.1-nano")
  
  def gpt_4o(), do: model("gpt-4o")
  def gpt_4o_audio(), do: model("gpt-4o-audio-preview")
  def gpt_4o_mini(), do: model("gpt-4o-mini")
  def gpt_4o_mini_audio(), do: model("gpt-4o-mini-audio-preview")
  def gpt_4o_realtime(), do: model("gpt-4o-realtime-preview")
  def gpt_4o_mini_realtime(), do: model("gpt-4o-mini-realtime-preview")
  def gtp_4o_mini_tts(), do: model("gpt-4o-mini-tts")
  
  def chatgpt_4o(), do: model("chatgpt-4o-latest")
  
  def gpt_o1(), do: model("o1")
  def gpt_o1_mini(), do: model("o1-mini")
  def gpt_o1_pro(), do: model("o1-pro")
  
  def gpt_o3(), do: model("o3")
  def gpt_o3_mini(), do: model("o3-mini")
  
  def gpt_o4_mini(), do: model("o4-mini")

  

  #=============================================
  # Private Methods
  #=============================================

  #-----------------
  # Prepare API Request Headers
  # @TODO - refactor out this copy pasta from open_ai.ex
  #-----------------
  defp headers(settings) do
    auth = cond do
      key = settings[:api_key] -> {"Authorization", "Bearer #{key}"}
      key = Application.get_env(:genai, :openai)[:api_key] -> {"Authorization", "Bearer #{key}"}
    end
    [auth, {"content-type", "application/json"}]
  end

  #------------------
  # Extract model from api request response.
  # @TODO move into Model module
  #------------------
  defp model_from_json(json) do
    {:ok, entry} = GenAI.ModelMetadata.ProviderBehaviour.get(@model_metadata_provider, GenAI.Provider.OpenAI, json[:id])
    entry
  end


end
