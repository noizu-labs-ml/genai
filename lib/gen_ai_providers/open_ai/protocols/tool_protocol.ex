

defprotocol GenAI.Provider.OpenAI.ToolProtocol do
  def tool(subject)
end

defimpl GenAI.Provider.OpenAI.ToolProtocol, for: GenAI.Tool.Function do
  def tool(subject) do
    %{type: :function, function: subject}
  end
end
