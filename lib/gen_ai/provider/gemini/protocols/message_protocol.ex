
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



defimpl GenAI.Provider.Gemini.MessageProtocol, for: GenAI.Message.ToolCall do
  def message(message) do
    tool_calls = Enum.map(message.tool_calls,
      fn(tc) ->
        %{
          function_call: %{
            name: tc.function.name,
            args: tc.function.arguments
          }
        }
      end
    )
    %{
      role: :model,
      parts: [
        tool_calls
      ],
    }
  end
end

defimpl GenAI.Provider.Gemini.MessageProtocol, for: GenAI.Message.ToolResponse do
  def message(message) do
    %{
      role: :function,
      parts: [
        %{
          function_response: %{
            name: message.name,
            response: %{
              name: message.name,
              content: message.response
            }
          }
        }
      ],
    }
  end
end
