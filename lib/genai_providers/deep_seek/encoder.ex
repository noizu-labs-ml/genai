defmodule GenAI.Provider.DeepSeek.Encoder do
  @base_url "https://api.deepseek.com"
  use GenAI.Model.EncoderBehaviour
  
  # or /beta for fim.
  def endpoint(_, _, session, _, _),
      do: {:ok, {{:post, "#{@base_url}/chat/completions"}, session}}
  
  
  def default_hyper_params(model, settings, session, context, options)
  def default_hyper_params(model, settings, session, context, options) do
    x = [
      
      hyper_param(name: :frequency_penalty),
      hyper_param(name: :max_tokens),
      hyper_param(name: :presence_penalty),
      hyper_param(name: :response_format),
      hyper_param(name: :stop_sequence, as: :stop),
      hyper_param(name: :stream),
      hyper_param(name: :stream_options),
      hyper_param(name: :temperature),
      
      hyper_param(name: :top_p),
      hyper_param(name: :tools),
      hyper_param(name: :tool_choice),
      hyper_param(name: :logprobs),
      hyper_param(name: :top_logprobs),
    ]
    {:ok, x}
  end
  
  
  
  def completion_response(json, model, settings, session, context, options)
  
  def completion_response(json, model, settings, session, context, options) do
    with {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         %{
           id: id,
           created: created_on,
           usage: %{},
           system_fingerprint: system_fingerprint,
           model: model,
           choices: choices
         } <- json do
      choices =
        choices
        |> Enum.map(
             &if {:ok, v} =
                   completion_choices(id, &1, model, settings, session, context, options),
                 do: v
           )
      
      usage = GenAI.ChatCompletion.Usage.new(json.usage)
      
      completion =
        %{json | usage: usage, choices: choices}
        |> put_in([Access.key(:provider)], provider)
        |> GenAI.ChatCompletion.from_json()
      
      {:ok, completion}
    end
  end
  
  
  def completion_choices(id, json, model, settings, session, context, options)
  
  @finish_reasons ~w(stop length content_filter tool_calls, insufficient_system_resources)
  
  def completion_choices(
        id,
        json = %{
          index: _,
          message: message,
          finish_reason: finish_reason,
          logprobs: logprobs,
        },
        model,
        settings,
        session,
        context,
        options
      ) do
    with {:ok, message_struct} <-
           completion_choice(id, message, model, settings, session, context, options) do

      # todo support data struct for log probs.
      finish_reason =
        if finish_reason in @finish_reasons,
           do: String.to_atom(finish_reason),
           else: finish_reason
      choice =
        json
        |> put_in([Access.key(:message)], message_struct)
        |> put_in([Access.key(:logprobs)], logprobs)
        |> put_in([Access.key(:finish_reason)], finish_reason)
        |> GenAI.ChatCompletion.Choice.new()
        
      {:ok, choice}
    end
  end
  
  def completion_choice(id, json, model, settings, session, context, options)
  
  
  def completion_choice(
        _,
        %{
          role: "assistant",
          tool_calls: tool_calls
        } = json,
        _,
        _,
        _,
        _,
        _
      )  do
    
    tool_calls =
      tool_calls
      |> Enum.map(fn
        %{
          id: id,
          type: "function",
          function: %{name: name, arguments: arguments_json},
        } = call ->
          arguments = case Jason.decode(arguments_json, keys: :atoms) do
            {:ok, arguments} -> arguments
            {:error, details} ->
              %{
                error: details,
                raw: arguments_json
              }
          end
          %GenAI.Message.ToolCall{
            id: id,
            type: :function,
            tool_name: name,
            arguments: arguments
          }
      end)
    
    content = [
                json[:reasoning_content] && %GenAI.Message.Content.ThinkingContent{thinking: json[:reasoning_content]},
                json[:content] && %GenAI.Message.Content.TextContent{text: json[:content]}
              ] |> Enum.reject(&is_nil/1)
              |> then(fn [] -> nil; x -> x end)
    msg = GenAI.Message.ToolUsage.new(role: :assistant, content: content, tool_calls: tool_calls)
    {:ok, msg}
  end
  
  def completion_choice(
        _,
        %{role: "assistant", content: content, reasoning_content: reasoning_content},
        _,
        _,
        _,
        _,
        _
      ) do
    
    content = [
      %GenAI.Message.Content.ThinkingContent{thinking: reasoning_content},
      %GenAI.Message.Content.TextContent{text: content}
    ]
    
    msg = GenAI.Message.assistant(content)
    {:ok, msg}
  end
  
  def completion_choice(
        _,
        %{role: "assistant", content: content},
        _,
        _,
        _,
        _,
        _
      ) do
    msg = GenAI.Message.assistant(content)
    {:ok, msg}
  end





end