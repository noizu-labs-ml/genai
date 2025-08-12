defmodule GenAI.Provider.Ollama.Models do
  @api_base "http://localhost:11434"
  @model_metadata_provider Application.compile_env(:genai, :ollama)[:metadata_provider] ||
                             GenAI.ModelMetadata.DefaultProvider

  import GenAI.InferenceProvider.Helpers

  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  def list(options \\ nil) do
    headers = GenAI.Provider.Ollama.headers(options)
    base_url = options[:base_url] || @api_base
    call = api_call(:get, "#{base_url}/api/tags", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{models: models} <- json do
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
      provider: GenAI.Provider.Ollama,
      encoder: GenAI.Provider.Ollama.Encoder
    }
  end

  # Common Ollama models
  def llama3_2(), do: model("llama3.2")
  def llama3_2_vision(), do: model("llama3.2-vision")
  def llama3_1(), do: model("llama3.1")
  def llama3(), do: model("llama3")
  def llama2(), do: model("llama2")

  def mistral(), do: model("mistral")
  def mixtral(), do: model("mixtral")

  def gemma2(), do: model("gemma2")
  def gemma(), do: model("gemma")

  def qwen2_5(), do: model("qwen2.5")
  def qwen2(), do: model("qwen2")

  def phi3(), do: model("phi3")
  def phi(), do: model("phi")

  def deepseek_coder_v2(), do: model("deepseek-coder-v2")

  def codellama(), do: model("codellama")
  def starcoder2(), do: model("starcoder2")

  def llava(), do: model("llava")

  def neural_chat(), do: model("neural-chat")

  def openhermes(), do: model("openhermes")

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
        GenAI.Provider.Ollama,
        json[:name]
      )

    entry
  end
end