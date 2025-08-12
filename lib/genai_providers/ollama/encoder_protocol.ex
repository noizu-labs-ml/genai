defprotocol GenAI.Provider.Ollama.EncoderProtocol do
  @moduledoc """
  Encoders use their module's EncoderProtocol to prep messages and tool definitions
  To make future extensibility for third parties straight forward. If a new message
  type, or tool type is added one simply needs to implement a EncoderProtocol for it
  and most cases you can simply cast it to generic known type and then invoke the protocol
  again.
  
  Ollama uses a similar format to OpenAI but with some differences.
  """
  def encode(subject, model, session, context, options)
end

# -----------------------------
# GenAI.Tool
# -----------------------------
defimpl GenAI.Provider.Ollama.EncoderProtocol, for: GenAI.Tool do
  def encode(subject, _model, session, _context, _options) do
    # Ollama tool format
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

# -----------------------------
# GenAI.Message
# -----------------------------
defimpl GenAI.Provider.Ollama.EncoderProtocol, for: GenAI.Message do
  def content(content)

  def content(content) when is_bitstring(content) do
    content
  end

  def content(%GenAI.Message.Content.TextContent{} = content) do
    content.text
  end

  def content(%GenAI.Message.Content.ImageContent{} = content) do
    # Ollama supports base64 encoded images
    {:ok, encoded} = GenAI.Message.Content.ImageContent.base64(content)
    encoded
  end

  def encode(subject, _model, session, _context, _options) do
    encoded =
      case subject.content do
        x when is_bitstring(x) ->
          %{role: subject.role, content: subject.content}

        x when is_list(x) ->
          # For Ollama, we need to handle mixed content differently
          # If there are images, they go in a separate images field
          {text_parts, image_parts} = 
            Enum.split_with(x, fn 
              %GenAI.Message.Content.TextContent{} -> true
              content when is_bitstring(content) -> true
              _ -> false
            end)
          
          text_content = 
            text_parts
            |> Enum.map(&content/1)
            |> Enum.join("\n")
          
          if Enum.empty?(image_parts) do
            %{role: subject.role, content: text_content}
          else
            images = Enum.map(image_parts, &content/1)
            %{role: subject.role, content: text_content, images: images}
          end
      end

    {:ok, {encoded, session}}
  end
end

# -----------------------------
# GenAI.Message.ToolResponse
# -----------------------------
defimpl GenAI.Provider.Ollama.EncoderProtocol, for: GenAI.Message.ToolResponse do
  def encode(subject, _model, session, _context, _options) do
    # Ollama format for tool responses
    encoded = %{
      role: :tool,
      content: Jason.encode!(subject.tool_response)
    }

    {:ok, {encoded, session}}
  end
end

# -----------------------------
# GenAI.Message.ToolUsage
# -----------------------------
defimpl GenAI.Provider.Ollama.EncoderProtocol, for: GenAI.Message.ToolUsage do
  def encode_call(%GenAI.Message.ToolCall{
        id: _id,
        type: _type,
        tool_name: tool_name,
        arguments: arguments
      }) do
    %{
      function: %{
        name: tool_name,
        arguments: arguments
      }
    }
  end

  def encode(subject, _model, session, _context, _options) do
    tool_calls = Enum.map(subject.tool_calls, &encode_call/1)

    encoded = %{
      role: subject.role,
      content: subject.content || "",
      tool_calls: tool_calls
    }

    {:ok, {encoded, session}}
  end
end