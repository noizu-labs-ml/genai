
defprotocol GenAI.Provider.OpenAI.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.OpenAI.MessageProtocol, for: GenAI.Message do
  def message(message) do
    %{role: message.role, content: message.content}
  end
end
