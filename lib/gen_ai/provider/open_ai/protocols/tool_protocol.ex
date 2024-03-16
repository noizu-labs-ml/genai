

defprotocol GenAI.Provider.OpenAI.ToolProtocol do
  def tool(subject)
end

defimpl GenAI.Provider.OpenAI.ToolProtocol, for: GenAI.Tool do
  def tool(subject) do
    subject
  end
end
