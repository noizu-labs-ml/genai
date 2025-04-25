defprotocol GenAI.Provider.Gemini.EncoderProtocol do
  @moduledoc """
  Encoders use their module's EncoderProtocol to prep messages and tool definitions
  To make future extensibility for third parties straight forward. If a new message
  type, or tool type is added one simply needs to implement a EncoderProtocol for it
  and most cases you can simply cast it to generic known type and then invoke the protocol
  again.
  """
  def encode(subject, model, session, context, options)
end

defmodule GenAI.Provider.Gemini.EncoderProtocolHelper do
  
  
  def system_message_markup(message) do
    "<|system|>\n" <> message <> "</|system|>"
  end
  
  def content(content, subject, model, session, context, options)
  
  def content(content, _, _, session, _, options) when is_bitstring(content) do
    system_message = options[:system_message]
    cond do
      system_message -> {%{text: system_message_markup(content)}, session}
      :else -> {%{text: content}, session}
    end
  end
  
  def content(%GenAI.Message.Content.TextContent{type: type, system: system_content, text: text} = content, _, _, session, _, options) do
    system_type = type in [:input, :prompt]
    system_message = options[:system_message]
    cond do
      !system_type ->  {%{text: text}, session}
      !(system_message || system_content) -> {%{text: text}, session}
      :else -> {%{text: system_message_markup(text)}, session}
    end
  end
  
  def content(%GenAI.Message.Content.ImageContent{} = content, _, _, session, _, _) do
    {:ok, encoded} = GenAI.Message.Content.ImageContent.base64(content)
    content = %{
      inlineData: %{
        data: encoded,
        mimeType: "image/#{content.type}",
      }
    }
    {content, session}
  end
  
  def content(%GenAI.Message.Content.AudioContent{} = content, _, _, session, _, _) do
    content = %{
      text: content.transcript
    }
    {content, session}
  end
  
  def content(%GenAI.Message.ToolCall{} = content, _, _, session, _, _) do
    content = %{
      function_call: %{
        name: content.tool_name,
        args: content.arguments
      }
    }
    {content, session}
  end
  
  def content(%GenAI.Message.Content.ToolUseContent{} = content, _, _, session, _, _) do
    content = %{
      function_call: %{
        name: content.tool_name,
        args: content.arguments
      }
    }
    {content, session}
  end
  
  
  def content(%GenAI.Message.ToolResponse{} = content, _, _, session, _, _) do
    content = %{
      function_response: %{
        name: content.tool_name,
        response: %{
          name: content.tool_name,
          content: content.tool_response
        }
      }
    }
    {content, session}
  end
  def content(%GenAI.Message.Content.ToolResultContent{} = content, _, _, session, _, _) do
    content = %{
      function_response: %{
        name: content.tool_name,
        response: %{
          name: content.tool_name,
          content: content.tool_response
        }
      }
    }
    {content, session}
  end
end

#-----------------------------
# GenAI.Tool
#-----------------------------
defimpl GenAI.Provider.Gemini.EncoderProtocol, for: GenAI.Tool do
  
  def encode(subject, model, session, context, options) do
    encoded = %{
      name: subject.name,
      description: subject.description,
      parameters: subject.parameters
    }
    {:ok, {encoded, session}}
  end
end

#-----------------------------
# GenAI.Message
#-----------------------------
defimpl GenAI.Provider.Gemini.EncoderProtocol, for: GenAI.Message do
  import GenAI.Provider.Gemini.EncoderProtocolHelper
  
  def encode(subject, model, session, context, options) do
    roles = %{
      user: :user,
      assistant: :model,
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
        {:ok, {%{role: role, parts: content}, session}}
    end
  end


end

#-----------------------------
# GenAI.Message.ToolResponse
#-----------------------------
defimpl GenAI.Provider.Gemini.EncoderProtocol, for: GenAI.Message.ToolResponse do
  import GenAI.Provider.Gemini.EncoderProtocolHelper
  
  def encode(subject, model, session, context, options) do
    {entry, session} = content(subject, subject, model, session, context, options)
    encoded = %{
      role: :function,
      parts: [entry],
    }
    {:ok, {encoded, session}}
  end
end

#-----------------------------
# GenAI.Message.ToolUsage
#-----------------------------
defimpl GenAI.Provider.Gemini.EncoderProtocol, for: GenAI.Message.ToolUsage do
  import GenAI.Provider.Gemini.EncoderProtocolHelper
  
  def encode(subject, model, session, context, options) do

  {content, session} =
      case subject.content do
        nil -> {[], session}
        content when is_bitstring(content) ->
          {content, session} = content(content, subject, model, session, context, options)
          {[content], session}
        content when is_list(content) ->
          Enum.map_reduce(
            content,
            session,
            &content(&1, subject, model, &2, context, options)
          )
      end
  
  {tool_use, session} =
    case subject.tool_calls do
      nil -> {[], session}
      content when is_bitstring(content) ->
        {content, session} = content(content, subject, model, session, context, options)
        {[content], session}
      content when is_list(content) ->
        Enum.map_reduce(
          content,
          session,
          &content(&1, subject, model, &2, context, options)
        )
    end
    encoded = %{role: :model, parts: content ++ tool_use}
    {:ok, {encoded, session}}
  end
end