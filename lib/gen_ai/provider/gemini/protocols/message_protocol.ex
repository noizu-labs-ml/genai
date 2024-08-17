
defprotocol GenAI.Provider.Gemini.MessageProtocol do
  def message(message)
end

defimpl GenAI.Provider.Gemini.MessageProtocol, for: GenAI.Message do

  # temp
  def content(content, options)
  def content(%GenAI.Message.Content.TextContent{} = content, options) do
    text = if options[:role] == :system do
      "<|system|>\n" <> content.text <> "</|system|>"
    else
      content.text
    end
    %{text: text}
  end
  def content(%GenAI.Message.Content.ImageContent{} = content, _options) do
    {:ok, encoded} = GenAI.Message.Content.ImageContent.base64(content)
    %{
      inlineData: %{
        data: encoded,
        mimeType: "image/#{content.type}",
      }
    }
  end

  def message(message) do
    case GenAI.MessageProtocol.content(message) do
      content when is_bitstring(content) ->
        case message.role do
          :user -> %{role: :user, parts: [%{text: content }] }
          :assistant -> %{role: :model, parts: [%{text: content }] }
          :system -> %{role: :user, parts: [%{text: "<|system|>\n" <> content <> "</|system|>"}] }
        end
      content when is_list(content) ->
        content_list = Enum.map(content, & content(&1, role: message.role))
        case message.role do
          :user -> %{role: :user, parts:  content_list}
          :assistant ->%{role: :assistant, parts:  content_list}
          :system -> %{role: :user, parts:  content_list}
        end
    end
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
