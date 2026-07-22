defmodule GenAI.Provider.Ollama.Models do
  @api_base "http://localhost:11434"
  @model_metadata_provider Application.compile_env(:genai, :ollama)[:metadata_provider] ||
                             GenAI.ModelMetadata.DefaultProvider

  import GenAI.InferenceProvider.Helpers

  # ⟦𓈫𓋶𓃉𓍗⟧ load_metadata :: auto-generated pointer for public function load_metadata
  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  # ⟦𓊥𓉸𓄊𓍔⟧ list :: auto-generated pointer for public function list
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

  # ⟦𓆃𓎰𓁰𓏧⟧ model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Ollama,
      encoder: GenAI.Provider.Ollama.Encoder
    }
  end

  # Common Ollama models
  # ⟦𓎝𓀭𓅒𓀢⟧ llama4 :: auto-generated pointer for public function llama4
  def llama4(), do: model("llama4")
  # ⟦𓃚𓍥𓂼𓀘⟧ llama3_2 :: auto-generated pointer for public function llama3_2
  def llama3_2(), do: model("llama3.2")
  # ⟦𓊕𓇃𓃋𓂀⟧ llama3_2_vision :: auto-generated pointer for public function llama3_2_vision
  def llama3_2_vision(), do: model("llama3.2-vision")
  # ⟦𓆋𓇇𓉖𓏲⟧ llama3_1 :: auto-generated pointer for public function llama3_1
  def llama3_1(), do: model("llama3.1")
  # ⟦𓍼𓃚𓃆𓂆⟧ llama3 :: auto-generated pointer for public function llama3
  def llama3(), do: model("llama3")

  # ⟦𓅊𓃨𓉂𓈲⟧ mistral :: auto-generated pointer for public function mistral
  def mistral(), do: model("mistral")
  # ⟦𓎴𓍻𓃠𓀆⟧ mixtral :: auto-generated pointer for public function mixtral
  def mixtral(), do: model("mixtral")

  # ⟦𓂃𓁌𓊆𓎮⟧ gemma3 :: auto-generated pointer for public function gemma3
  def gemma3(), do: model("gemma3")
  # ⟦𓌻𓏍𓃷𓐤⟧ gemma2 :: auto-generated pointer for public function gemma2
  def gemma2(), do: model("gemma2")

  # ⟦𓊘𓍘𓍻𓆼⟧ qwen3 :: auto-generated pointer for public function qwen3
  def qwen3(), do: model("qwen3")
  # ⟦𓎶𓈥𓂒𓁾⟧ qwen2_5 :: auto-generated pointer for public function qwen2_5
  def qwen2_5(), do: model("qwen2.5")

  # ⟦𓊔𓉑𓎺𓐤⟧ phi4 :: auto-generated pointer for public function phi4
  def phi4(), do: model("phi4")
  # ⟦𓋱𓂿𓈦𓇉⟧ phi3 :: auto-generated pointer for public function phi3
  def phi3(), do: model("phi3")

  # ⟦𓋝𓋂𓇝𓏳⟧ deepseek_r1 :: auto-generated pointer for public function deepseek_r1
  def deepseek_r1(), do: model("deepseek-r1")
  # ⟦𓄕𓈋𓄑𓃭⟧ deepseek_coder_v2 :: auto-generated pointer for public function deepseek_coder_v2
  def deepseek_coder_v2(), do: model("deepseek-coder-v2")

  # ⟦𓍠𓋵𓈸𓂎⟧ codellama :: auto-generated pointer for public function codellama
  def codellama(), do: model("codellama")
  # ⟦𓍴𓄪𓃅𓈏⟧ starcoder2 :: auto-generated pointer for public function starcoder2
  def starcoder2(), do: model("starcoder2")

  # ⟦𓊧𓐍𓆚𓄝⟧ llava :: auto-generated pointer for public function llava
  def llava(), do: model("llava")

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