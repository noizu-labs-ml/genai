defprotocol GenAI.Provider.DeepSeek.EncoderProtocol do
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
defimpl GenAI.Provider.DeepSeek.EncoderProtocol, for: GenAI.Tool  do
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
defimpl GenAI.Provider.DeepSeek.EncoderProtocol, for: GenAI.Message do
  def content(content)
  def content(content) when is_bitstring(content) do
    content
  end
  def content(%GenAI.Message.Content.TextContent{} = content) do
    content.text
  end
  def content(%GenAI.Message.Content.ImageContent{} = content) do
    "AN IMAGE WAS INCLUDED IN THE MESSAGE: (TODO: IMAGE TO TEXT CAPTIONS)"
  end
  def content(%GenAI.Message.Content.AudioContent{} = content) do
    content.transcript
  end
  def content(%GenAI.Message.Content.ToolUseContent{} = content) do
    %{
      id: content.id,
      type: :function,
      function: %{
        name: content.tool_name,
        arguments: Jason.encode!(content.arguments)
      }
    }
  end
  def content(%GenAI.Message.ToolCall{} = content) do
    %{
      id: content.id,
      type: :function,
      function: %{
        name: content.tool_name,
        arguments: Jason.encode!(content.arguments)
      }
    }
  end
  
  def content(content) do
    """
    UNSUPPORTED MESSAGE PART:
    #{inspect content, limit: :infinity, pretty: true}
    """
  end
  
  def encode(subject, model, session, context, options) do
    encoded =
      case subject.content do
        x when is_bitstring(x) ->
          %{role: subject.role, content: subject.content}
        x when is_list(x) ->
          reasoning = x
                      |> Enum.filter(fn %GenAI.Message.Content.ThinkingContent{} -> true; _ -> false end)
                      |> Enum.map(&content/1)
                      |> Enum.join("\n ------------------------ \n")
          tool_calls = x
                       |> Enum.filter(
                            fn
                              %GenAI.Message.Content.ToolUseContent{} -> true
                              %GenAI.Message.ToolCall{} -> true
                              _ -> false end
                          )
                       |> Enum.map(&content/1)
                       |> Enum.reject(&is_nil/1)
          content = x
                    |> Enum.reject(
                         fn
                           %GenAI.Message.Content.ThinkingContent{} -> true;
                           %GenAI.Message.Content.ToolUseContent{} -> true
                           %GenAI.Message.ToolCall{} -> true
                           _ -> false end
                       )
                    |> Enum.map(&content/1)
                    |> Enum.reject(&is_nil/1)
                    |> Enum.join("\n ------------------------ \n")
          
          %{role: subject.role, content: content}
          |> then(
               & if tool_calls != [],
                    do: put_in(&1, [Access.key(:tool_calls)], tool_calls),
                    else: &1
             )
          |> then(
               & if reasoning != "",
                    do: put_in(&1, [Access.key(:reasoning_content)], reasoning),
                    else: &1
             )
      end
      |> then(
           & if subject.user,
                do: put_in(&1, [Access.key(:name)], subject.user),
                else: &1
         )
    {:ok, {encoded, session}}
  end
end

#-----------------------------
# GenAI.Message.ToolResponse
#-----------------------------
defimpl GenAI.Provider.DeepSeek.EncoderProtocol, for: GenAI.Message.ToolResponse do
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
defimpl GenAI.Provider.DeepSeek.EncoderProtocol, for: GenAI.Message.ToolUsage do
  def content(content)
  def content(content) when is_bitstring(content) do
    content
  end
  def content(%GenAI.Message.Content.TextContent{} = content) do
    content.text
  end
  def content(%GenAI.Message.Content.ImageContent{} = content) do
    "AN IMAGE WAS INCLUDED IN THE MESSAGE: (TODO: IMAGE TO TEXT CAPTIONS)"
  end
  def content(%GenAI.Message.Content.AudioContent{} = content) do
    content.transcript
  end
  def content(%GenAI.Message.Content.ToolUseContent{} = content) do
    %{
      id: content.id,
      type: :function,
      function: %{
        name: content.tool_name,
        arguments: Jason.encode!(content.arguments)
      }
    }
  end
  def content(%GenAI.Message.ToolCall{} = content) do
    %{
      id: content.id,
      type: :function,
      function: %{
        name: content.tool_name,
        arguments: Jason.encode!(content.arguments)
      }
    }
  end
  
  def content(content) do
    """
    UNSUPPORTED MESSAGE PART:
    #{inspect content, limit: :infinity, pretty: true}
    """
  end
  
  def encode(subject, model, session, context, options) do
    content = cond do
      is_list(subject.content) -> subject.content
      is_bitstring(subject.content) -> [subject.content]
    end
    
    reasoning = content
                |> Enum.filter(fn %GenAI.Message.Content.ThinkingContent{} -> true; _ -> false end)
                |> Enum.map(&content/1)
                |> Enum.join("\n ------------------------ \n")
    
    tool_calls = content
                         |> Enum.filter(
                              fn
                                %GenAI.Message.Content.ToolUseContent{} -> true
                                %GenAI.Message.ToolCall{} -> true
                                _ -> false end
                            )
    tool_calls = (tool_calls ++ (subject.tool_calls || []))
                 |> Enum.map(&content/1)
                 |> Enum.reject(&is_nil/1)
    
    content = content
              |> Enum.reject(
                   fn
                     %GenAI.Message.Content.ThinkingContent{} -> true;
                     %GenAI.Message.Content.ToolUseContent{} -> true
                     %GenAI.Message.ToolCall{} -> true
                     _ -> false end
                 )
              |> Enum.map(&content/1)
              |> Enum.reject(&is_nil/1)
              |> Enum.join("\n ------------------------ \n")
    
    encoded = %{
                role: subject.role,
                content: content,
                tool_calls: tool_calls,
              }
              |> then(
                   & if reasoning != "",
                        do: put_in(&1, [Access.key(:reasoning_content)], reasoning),
                        else: &1
                 )
              |> then(
                   & if subject.user,
                        do: put_in(&1, [Access.key(:name)], subject.user),
                        else: &1
                 )
    {:ok, {encoded, session}}
  end
end


