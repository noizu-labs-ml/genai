

defprotocol GenAI.Provider.Anthropic.ToolProtocol do
  def tool(subject)
end

defimpl GenAI.Provider.Anthropic.ToolProtocol, for: GenAI.Tool.Function do
  def tool(subject) do
    subject
  end
end
