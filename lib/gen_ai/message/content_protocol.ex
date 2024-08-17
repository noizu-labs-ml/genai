defprotocol GenAI.Message.ContentProtocol do
  def content(message)
end


defimpl GenAI.Message.ContentProtocol, for: BitString do
  def content(text) do
    %GenAI.Message.Content.TextContent{text: text}
  end
end
