defprotocol GenAI.Provider.Anthropic.EncoderProtocol do
  @moduledoc """
  Encoders use their module's EncoderProtocol to prep messages and tool definitions
  To make future extensibility for third parties straight forward. If a new message
  type, or tool type is added one simply needs to implement a EncoderProtocol for it
  and most cases you can simply cast it to generic known type and then invoke the protocol
  again.
  """
  def encode(subject, model, session, context, options)
end

defmodule GenAI.Provider.Anthropic.EncoderProtocolHelper do
  
  
  def system_message_markup(message) do
    "<|system|>\n" <> message <> "</|system|>"
  end
  
  def content(content, subject, model, session, context, options)
  
  def content(%GenAI.Message.Content.TextContent{type: type, system: system_content, text: text} = content, _, _, session, _, options) do
    system_type = type in [:input, :prompt]
    system_message = options[:system_message]
    cond do
      !system_type ->  {%{type: :text, text: system_message_markup(text)}, session}
      !(system_message || system_content) -> {%{type: :text, text: system_message_markup(text)}, session}
      :else -> {%{type: :text, text: system_message_markup(text)}, session}
    end
  end
  
  def content(%GenAI.Message.Content.ImageContent{} = content, _, _, session, _, _) do
    {:ok, encoded} = GenAI.Message.Content.ImageContent.base64(content)
    content = %{
      type: :image,
      source: %{
        type: :base64,
        media_type: content.type,
        data: encoded
      }
    }
    {content, session}
  end
  
  def content(%GenAI.Message.Content.AudioContent{} = content, _, _, session, _, _) do
    content = %{
      type: :text,
      text: content.transcript
    }
    {content, session}
  end
  
  
  def content(%GenAI.Message.ToolUsage{} = content, _, _, session, _, _) do
    content = %{
      id: content.id,
      type: :tool_use,
      name: content.tool_name,
      input: content.arguments
    }
    {content, session}
  end
  
  def content(%GenAI.Message.Content.ToolUseContent{} = content, _, _, session, _, _) do
    content = %{
      id: content.id,
      type: :tool_use,
      name: content.tool_name,
      input: content.arguments
    }
    {content, session}
  end
  
  
  def content(%GenAI.Message.ToolResponse{} = content, _, _, session, _, _) do
    content = %{
      type: :tool_result,
      tool_use_id: content.tool_call_id,
      content: content.tool_response
    }
    {content, session}
  end
  def content(%GenAI.Message.Content.ToolResultContent{} = content, _, _, session, _, _) do
    content = %{
      type: :tool_result,
      tool_use_id: content.tool_use_id,
      content: content.response
    }
    {content, session}
  end
end

#-----------------------------
# GenAI.Tool
#-----------------------------
defimpl GenAI.Provider.Anthropic.EncoderProtocol, for: GenAI.Tool do
  def encode(subject, model, session, context, options) do
    encoded = %{
        name: subject.name,
        description: subject.description,
        input_schema: subject.parameters
    }
    {:ok, {encoded, session}}
  end
end

#-----------------------------
# GenAI.Message
#-----------------------------
defimpl GenAI.Provider.Anthropic.EncoderProtocol, for: GenAI.Message do
  import GenAI.Provider.Anthropic.EncoderProtocolHelper
  
  def encode(subject, model, session, context, options, _, _, session, _, _) do
    roles = %{
      user: :user,
      assistant: :assistant,
      system: :user
    }
    role = subject.role
    system_message = subject.role == :system
    put_in(options || [], [:system_message], system_message)
    case subject.content do
      content when is_bitstring(content) ->
        content = if system_message,
                     do:  system_message_markup(content),
                     else: content
        {:ok, {%{role: role, content: content}, session}}
      content when is_list(content) ->
        {content, session} =
          Enum.map_reduce(
            content,
            session,
            &content(&1, subject, model, &2, context, options)
          )
        {:ok, {%{role: role, content: content}, session}}
    end
  end
  
  
end

#-----------------------------
# GenAI.Message.ToolResponse
#-----------------------------
defimpl GenAI.Provider.Anthropic.EncoderProtocol, for: GenAI.Message.ToolResponse do
  import GenAI.Provider.Anthropic.EncoderProtocolHelper
  
  def encode(subject, model, session, context, options) do
    {entry, session} = content(subject, subject, model, session, context, options)
    encoded = %{
      role: :user,
      content: [
        entry
      ]
    }
    {:ok, {encoded, session}}
  end
end

#-----------------------------
# GenAI.Message.ToolUsage
#-----------------------------
defimpl GenAI.Provider.Anthropic.EncoderProtocol, for: GenAI.Message.ToolUsage do
  import GenAI.Provider.Anthropic.EncoderProtocolHelper
  
  def encode(subject, model, session, context, options) do
    {content, session} =
      case subject.content do
        nil -> {[], session}
        
        content when is_bitstring(content) ->
          content = [%{type: :text, text: content}]
          {content, session}
        
        content when is_list(content) ->
          Enum.map_reduce(
            content,
            session,
            &content(&1, subject, model, &2, context, options)
          )
      end
    
    tool_calls =
      case subject.tool_calls do
        calls when is_list(calls) -> calls
        call = %GenAI.Message.ToolCall{} -> [call]
        _ -> []
      end
    
    {tool_use, session} =
      Enum.map_reduce(
        tool_calls,
        session,
        &content(&1, subject, model, &2, context, options)
      )
    
    content = content ++ tool_use
    encoded = %{role: :assistant, content: content}
    {:ok, {encoded, session}}
  end
end