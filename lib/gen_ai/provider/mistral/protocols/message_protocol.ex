
defprotocol GenAI.Provider.Mistral.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.Mistral.MessageProtocol, for: GenAI.Message do
  def message(message) do
    %{role: message.role, content: message.content}
  end
end
