defmodule GenAI.Provider.OpenAI.Models do
  import GenAI.Provider
  @api_base "https://api.openai.com"
  @model_metadata_provider (Application.compile_env(:genai, :openai)[:metadata_provider] || GenAI.ModelMetadata.DefaultProvider)
  @behaviour GenAI.Provider.ModelsBehaviour

  def load_metadata(options \\ nil)
  def load_metadata(_) do
    :ok
  end

  def list(options \\ nil) do
    headers = headers(options)
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

  def gpt_3_5_turbo() do
    %GenAI.Model{
      model: "gpt-3.5-turbo",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_3_5_turbo_16k() do
    %GenAI.Model{
      model: "gpt-3.5-turbo",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4() do
    %GenAI.Model{
      model: "gpt-4",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4_turbo() do
    %GenAI.Model{
      model: "gpt-4-turbo",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4_turbo_preview() do
    %GenAI.Model{
      model: "gpt-4-turbo-preview",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4_vision() do
    %GenAI.Model{
      model: "gpt-4",
      provider: GenAI.Provider.OpenAI
    }
  end


  def gpt_4o() do
    %GenAI.Model{
      model: "gpt-4o",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4o_mini() do
    %GenAI.Model{
      model: "gpt-4o-mini",
      provider: GenAI.Provider.OpenAI
    }
  end


  def o1() do
    o1_preview()
  end

  def o1_preview() do
    %GenAI.Model{
      model: "o1-preview",
      provider: GenAI.Provider.OpenAI,
      details: %GenAI.Model.Details{
        hyper_params: %GenAI.ModelDetail.HyperParamSupport{disabled: MapSet.new([:temperature])},
        tool_usage: %GenAI.ModelDetail.ToolUsage{support: :disabled}
      }
    }
  end

  def o1_mini() do
    %GenAI.Model{
      model: "o1-mini",
      provider: GenAI.Provider.OpenAI,
      details: %GenAI.Model.Details{
        hyper_params: %GenAI.ModelDetail.HyperParamSupport{disabled: MapSet.new([:temperature])},
        tool_usage: %GenAI.ModelDetail.ToolUsage{support: :disabled}
      }
    }
  end

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
