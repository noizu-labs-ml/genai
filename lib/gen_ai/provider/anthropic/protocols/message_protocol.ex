
defprotocol GenAI.Provider.Anthropic.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.Anthropic.MessageProtocol, for: GenAI.Message do
  def message(message) do
    role = case message.role do
      :user -> :user
      :assistant -> :assistant
      :system -> :user
    end
    %{role: role, content: message.content}
  end
end
