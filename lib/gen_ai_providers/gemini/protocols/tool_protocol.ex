

defprotocol GenAI.Provider.Gemini.ToolProtocol do
  def tool(subject)
end

defimpl GenAI.Provider.Gemini.ToolProtocol, for: GenAI.Tool.Function do
  def tool(subject) do
    subject
  end
end
