defprotocol GenAI.ModelProtocol do
  @fallback_to_any true
  def protocol_supported?(model)
  def identifier(model)
  def provider(model)
  def model(model)
  def register(model, state)
end

defimpl GenAI.ModelProtocol, for: Any do
  def protocol_supported?(_), do: false
  def identifier(_), do: {:error, :unsupported}
  def provider(_), do: {:error, :unsupported}
  def model(_), do: {:error, :unsupported}
  def register(_,_), do: {:error, :unsupported}
end

#
#defprotocol GenAI.ExternalModelProtocol do
#  @fallback_to_any true
#  def protocol_supported?(model)
#
#  @type model :: any
#  @type sink :: pid
#
#  @doc """
#  Initialize for inference some external/non-api model.
#
#  # Examples of External Models
#  - An ExLLama model that must be loaded into memory before running inference.
#  - An Ollama provided endpoint whose service must be started before invoking.
#  - A hugging face endpoint that needs to be warmed before inference.
#
#  It is the responsibility of the external_model_manager to manage persisted state between calls.
#  """
#  @spec initialize(model, sink) :: {:ok, term} | {:error, term}
#  def initialize(model, sink)
#
#  @spec model(model, sink) :: {:ok, term} | {:error, term}
#  def model(model, sink)
#
#  @spec uninitialize(model, sink) :: {:ok, term} | {:error, term}
#  def uninitialize(model, sink)
#end
#
#defimpl GenAI.ExternalModelProtocol, for: Any do
#  def protocol_supported?(_), do: false
#  def load(model), do: {:error, :unsupported}
#  def status(model), do: {:error, :unsupported}
#  def unload(model), do: {:error, :unsupported}
#end
