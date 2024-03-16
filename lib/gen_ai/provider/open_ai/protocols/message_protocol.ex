
defprotocol GenAI.Provider.OpenAI.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.OpenAI.MessageProtocol, for: GenAI.Message do
  def message(message) do
    %{role: message.role, content: message.content}
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
