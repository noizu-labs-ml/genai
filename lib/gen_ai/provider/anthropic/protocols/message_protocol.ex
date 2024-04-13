
defprotocol GenAI.Provider.Anthropic.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.Anthropic.MessageProtocol, for: GenAI.Message do
  def message(message) do
    role = case message.role do
      :user -> %{role: :user, content:  message.content}
      :assistant ->%{role: :assistant, content:  message.content}
      :system -> %{role: :user, content:  "<|system|>\n" <> message.content <> "</|system|>"}
    end
  end
end


defimpl GenAI.Provider.Anthropic.MessageProtocol, for: GenAI.Message.ToolCall do
  def message(message) do
    tool_calls = Enum.map(message.tool_calls,
      fn(tc) ->
        """
        <invoke tool_call_id="#{tc.id}">
          <tool_name>tc.function.name</tool_name>
          <parameters>#{tc.function.arguments && Jason.encode!(tc.function.arguments)}</parameters>
        </invoke>
        """
      end
    ) |> Enum.join("\n")
    content = """
    #{message.content}
    ---
    <function_calls>
    #{tool_calls}
    </function_calls>
    """

    %{
      role: :assistant,
      content: content,
    }
  end
end


defimpl GenAI.Provider.Anthropic.MessageProtocol, for: GenAI.Message.ToolResponse do
  def message(message) do
    content = """
    <function_response for_tool_call_id="#{message.tool_call_id}">
    #{Jason.encode!(message.response)}
    </function_response>
    """

    %{
      role: :user,
      content: content
    }
  end
end
