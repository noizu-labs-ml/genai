defprotocol GenAI.ModelProtocol do
  @fallback_to_any true
  def protocol_supported?(model)
  def provider(model)
  def model(model)
end

defimpl GenAI.ModelProtocol, for: Any do
  def protocol_supported?(_), do: false
  def provider(_), do: {:error, :unsupported}
  def model(_), do: {:error, :unsupported}
end
