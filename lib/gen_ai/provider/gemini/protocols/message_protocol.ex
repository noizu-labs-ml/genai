
defprotocol GenAI.Provider.Gemini.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.Gemini.MessageProtocol, for: GenAI.Message do
  def message(message) do
    role = case message.role do
      :user -> :user
      :assistant -> :model
    end
    %{role: role, parts: [%{text: message.content }] }
  end
end
