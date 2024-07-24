defprotocol GenAI.ToolProtocol do
  @fallback_to_any true
  def protocol_supported?(tool)
  def name(model)
end

defimpl GenAI.ToolProtocol, for: Any do
  def protocol_supported?(_), do: false
  def name(_), do: {:error, :unsupported}
end
