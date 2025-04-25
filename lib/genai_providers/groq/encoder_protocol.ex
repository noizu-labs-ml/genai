defprotocol GenAI.Provider.Groq.EncoderProtocol do
  @moduledoc """
  Encoders use their module's EncoderProtocol to prep messages and tool definitions
  To make future extensibility for third parties straight forward. If a new message
  type, or tool type is added one simply needs to implement a EncoderProtocol for it
  and most cases you can simply cast it to generic known type and then invoke the protocol
  again.
  """
  def encode(subject, model, session, context, options)
end


#-----------------------------
# GenAI.Tool
#-----------------------------
defimpl GenAI.Provider.Groq.EncoderProtocol, for: GenAI.Tool do
  def encode(subject, model, session, context, options) do
    encoded = %{
      type: :function,
      function: %{
        name: subject.name,
        description: subject.description,
        parameters: subject.parameters
      }
    }
    {:ok, {encoded, session}}
  end
end

#-----------------------------
# GenAI.Message
#-----------------------------
defimpl GenAI.Provider.Groq.EncoderProtocol, for: GenAI.Message do
  def content(content)
  def content(content) when is_bitstring(content) do
    %{type: :text, text: content}
  end
  def content(%GenAI.Message.Content.TextContent{} = content) do
    %{type: :text, text: content.text}
  end
  def content(%GenAI.Message.Content.ImageContent{} = content) do
    {:ok, encoded} = GenAI.Message.Content.ImageContent.base64(content)
    base64 = "data:image/#{content.type};base64," <> encoded
    %{type: :image_url, image_url: base64}
  end
  
  def encode(subject, model, session, context, options) do
    encoded =
      case subject.content do
        x when is_bitstring(x) ->
          %{role: subject.role, content: subject.content}
        x when is_list(x) ->
          content_list = Enum.map(x, &content/1)
          %{role: subject.role, content: content_list}
      end

    encode = if subject.user,
                do: Map.put(encoded, :name, subject.user),
                else: encoded
    
    {:ok, {encoded, session}}
  end
end

#-----------------------------
# GenAI.Message.ToolResponse
#-----------------------------
defimpl GenAI.Provider.Groq.EncoderProtocol, for: GenAI.Message.ToolResponse do
  def encode(subject, model, session, context, options) do
    encoded = %{
      role: :tool,
      tool_call_id: subject.tool_call_id,
      content: Jason.encode!(subject.tool_response)
    }
    {:ok, {encoded, session}}
  end
end

#-----------------------------
# GenAI.Message.ToolUsage
#-----------------------------
defimpl GenAI.Provider.Groq.EncoderProtocol, for: GenAI.Message.ToolUsage do
  def encode_call(
        %GenAI.Message.ToolCall{
          id: id,
          type: type,
          tool_name: tool_name,
          arguments: arguments
        }
      ) do
    %{
      function: %{name: tool_name, arguments: Jason.encode!(arguments)},
      id: id,
      type: type
    }
  end
  
  def encode(subject, model, session, context, options) do
    tool_calls = Enum.map(subject.tool_calls,& encode_call/1)
    
    encoded = %{
      role: subject.role,
      content: subject.content,
      tool_calls: tool_calls
    }
    {:ok, {encoded, session}}
  end
end