
defprotocol GenAI.Provider.OpenAI.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.OpenAI.MessageProtocol, for: GenAI.Message do

  # temp
  def content(content)
  def content(%GenAI.Message.Content.TextContent{} = content) do
    %{type: :text, text: content.text}
  end
  def content(%GenAI.Message.Content.ImageContent{} = content) do
    {:ok, encoded} = GenAI.Message.Content.ImageContent.base64(content)
    base64 = "data:image/#{content.type};base64," <> encoded
    %{type: :image_url, image_url: %{url:  base64}}
  end

  def message(message) do
    case GenAI.MessageProtocol.content(message) do
      content when is_bitstring(content) ->
        %{role: message.role, content: content}
      content when is_list(content) ->
        content_list = Enum.map(content, &content/1)
        %{role: message.role, content: content_list}
    end
  end
end

defimpl GenAI.Provider.OpenAI.MessageProtocol, for: GenAI.Message.ToolCall do
  def message(message) do
    tool_calls = Enum.map(message.tool_calls,
                       fn(tc) ->
                       put_in(tc, [Access.key(:function), Access.key(:arguments)], tc.function.arguments && Jason.encode!(tc.function.arguments))
                       end
    )

    %{
      role: message.role,
      content: message.content,
      tool_calls: tool_calls
    }
  end
end


defimpl GenAI.Provider.OpenAI.MessageProtocol, for: GenAI.Message.ToolResponse do
  def message(message) do
    %{
      role: :tool,
      tool_call_id: message.tool_call_id,
      content: Jason.encode!(message.response)
    }
  end
end
