defmodule GenAI.Provider.Anthropic.Encoder do
  @base_url "https://api.anthropic.com"
  use GenAI.Model.EncoderBehaviour
  
  def endpoint(model, settings, session, context, options)
  def endpoint(_, _, session ,_ ,_),
      do: {:ok, {{:post, "#{@base_url}/v1/messages"}, session}}
  
  def headers(model, settings, session, context, options) do
    
      search_scope = [
        options,
        settings[:model_settings],
        settings[:provider_settings],
        settings[:settings],
        settings[:config_settings],
      ]
    
      headers = [{"content-type", "application/json"}]
      headers = search_scope
                |> Enum.find_value(& &1[:anthropic_beta])
                |> then(& &1 && [{"anthropic-beta", &1} | headers] || headers)
      headers = search_scope
                |> Enum.find_value(& &1[:anthropic_version])
                |> then(&  [{"anthropic-version", &1 || "2023-06-01"} | headers])
      headers = search_scope
                |> Enum.find_value(& &1[:api_key])
                |> then(& &1 && [{"x-api-key", &1} | headers] || headers)
      
      {:ok, {headers, session}}
    
  end
  
  def default_hyper_params(model, settings, session, context, options)
  def default_hyper_params(model, settings, session, context, options) do
    x = [
      
      hyper_param(name: :max_tokens),
      hyper_param(name: :metadata),
      hyper_param(name: :stop_sequence),
      hyper_param(name: :stream),
      hyper_param(name: :system_prompt, as: :system),
      hyper_param(name: :temperature),
      hyper_param(name: :thinking),
      hyper_param(name: :tool_choice),
      
      hyper_param(name: :top_k),
      hyper_param(name: :top_p),
    ]
    {:ok, x}
  end




  def completion_response(json, model, settings, session, context, options)

  def completion_response(json, model, settings, session, context, options) do
    with {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         %{
           id: id,
           model: model_name,
           stop_reason: _,
           content: content
         } <- json do

      {:ok, choice} = completion_choices(id, json, model, settings, session, context, options)
      choices = [choice]
      prompt_tokens = json[:usage][:input_tokens] || 0
      completion_tokens = json[:usage][:output_tokens] || 0

      usage = GenAI.ChatCompletion.Usage.new(
        prompt_tokens: prompt_tokens,
        total_tokens: prompt_tokens + completion_tokens,
        completion_tokens: completion_tokens
      )

      completion = GenAI.ChatCompletion.from_json(
        id: id,
        model: model_name,
        provider: provider,
        choices: choices,
        usage: usage
      )
      {:ok, completion}
    end
  end

  def completion_choices(id, json, model, settings, session, context, options)

  def completion_choices(
        id,
        json,
        model,
        settings,
        session,
        context,
        options
      ) do


    with {:ok, message} <-
           completion_choice(id, json, model, settings, session, context, options) do
      choice = GenAI.ChatCompletion.Choice.new(
        id: json.id,
        index: 0,
        message: message,
        finish_reason: json.stop_reason
      )
      {:ok, choice}
    end
  end

  def completion_choice(id, json, model, settings, session, context, options)

  def completion_choice(
        _,
        json = %{
        id: id,
        model: _,
        stop_reason: "tool_use",
        content: content
        },
        _,
        _,
        _,
        _,
        _
      ) do

    content = completion_message(json)
#    tool_calls = Enum.filter(content, & &1.__struct__ == GenAI.Message.ToolCall)
#    content = Enum.reject(content, & &1.__struct__ == GenAI.Message.ToolCall)
#              |> then(& &1 != [] && &1)

    msg = GenAI.Message.ToolUsage.new(id: id, role: :assistant, content: content, tool_calls: [])
    {:ok, msg}
  end

  def completion_choice(
        _,
        json = %{
          id: id,
          model: _,
          stop_reason: _,
          content: content
        },
        _,
        _,
        _,
        _,
        _
      ) do

    content = completion_message(json)
    msg = GenAI.Message.assistant(content, id: id)
    {:ok, msg}
  end

  def completion_message(%{content: content}) when is_bitstring(content) do
    Enum.map([content], &completion_content/1)
  end
  def completion_message(%{content: content}) when is_list(content) do
    Enum.map(content, &completion_content/1)
  end

  def completion_content(json)
  def completion_content(%{id: id, type: "tool_use", name: tool_name, input: arguments}) do
    %GenAI.Message.Content.ToolUseContent{
      id: id,
      tool_name: tool_name,
      arguments: arguments
    }
  end

  def completion_content(%{type: "text", text: text} = json)  do
    %GenAI.Message.Content.TextContent{
      system: false,
      type: :response,
      text: text,
      citations: json[:citations]
    }
  end


  def completion_content(%{type: "thinking"} = json)  do
    %GenAI.Message.Content.ThinkingContent{
      thinking: json[:thinking],
      signature: json[:signature]
    }
  end

  def completion_content(%{type: "redacted_thinking"} = json)  do
    %GenAI.Message.Content.RedactedThinkingContent{
      data: json[:data],
    }
  end

  def completion_content(%{type: "image"} = json)  do
   media_types = %{
      "image/jpeg" => :jpeg,
      "image/png" => :png,
      "image/gif" => :gif,
      "image/webp" => :webp,
      "image/svg+xml" => :svg,
    }

    %GenAI.Message.Content.ImageContent{
      source: :anthropic,
      type: media_types[json[:souce][:media_type]],
      resolution: :auto,
      resource: {:base64, json[:source][:data]},
      options: nil,
    }
  end



end
