

defprotocol GenAI.Provider.Mistral.ToolProtocol do
  def tool(subject)
end

defimpl GenAI.Provider.Mistral.ToolProtocol, for: GenAI.Tool.Function do
  def tool(subject) do
    subject
  end
end
