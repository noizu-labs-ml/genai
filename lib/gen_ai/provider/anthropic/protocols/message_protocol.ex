
defprotocol GenAI.Provider.Anthropic.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.Anthropic.MessageProtocol, for: GenAI.Message do

  # temp
  def content(content, options)
  def content(%GenAI.Message.Content.TextContent{} = content, options) do
    text = if options[:role] == :system do
      content = "<|system|>\n" <> content.text <> "</|system|>"
    else
      content = content.text
    end
    %{type: :text, text: text}
  end
  def content(%GenAI.Message.Content.ImageContent{} = content, _options) do
    {:ok, encoded} = GenAI.Message.Content.ImageContent.base64(content)
    %{
      type: :image,
      source: %{
        type: :base64,
        media_type: "image/#{content.type}",
        data: encoded
      }
    }
  end

  def message(message) do
    case GenAI.MessageProtocol.content(message) do
      content when is_bitstring(content) ->
        case message.role do
          :user -> %{role: :user, content:  content}
          :assistant ->%{role: :assistant, content:  content}
          :system -> %{role: :user, content:  "<|system|>\n" <> content <> "</|system|>"}
        end
      content when is_list(content) ->
        content_list = Enum.map(content, & content(&1, role: message.role))
        case message.role do
          :user -> %{role: :user, content:  content_list}
          :assistant ->%{role: :assistant, content:  content_list}
          :system -> %{role: :user, content:  content_list}
        end
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
