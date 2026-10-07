defmodule GenAI.Provider.Anthropic.Encoder do
  @base_url "https://api.anthropic.com"
  require Logger
  use GenAI.Model.EncoderBehaviour

  # ⟦𓄎𓉟𓇧𓃝⟧ endpoint :: auto-generated pointer for public function endpoint
  def endpoint(model, settings, session, context, options)

  def endpoint(_, _, session, _, _),
    do: {:ok, {{:post, "#{@base_url}/v1/messages"}, session}}

  # ⟦𓎙𓉸𓃝𓀖⟧ headers :: auto-generated pointer for public function headers
  def headers(_model, settings, session, _context, options) do
    search_scope = [
      options,
      settings[:model_settings],
      settings[:provider_settings],
      settings[:settings],
      settings[:config_settings]
    ]

    headers = [{"content-type", "application/json"}]

    headers =
      search_scope
      |> Enum.find_value(& &1[:anthropic_beta])
      |> then(&((&1 && [{"anthropic-beta", &1} | headers]) || headers))

    headers =
      search_scope
      |> Enum.find_value(& &1[:anthropic_version])
      |> then(&[{"anthropic-version", &1 || "2023-06-01"} | headers])

    headers =
      search_scope
      |> Enum.find_value(& &1[:api_key])
      |> then(&((&1 && [{"x-api-key", &1} | headers]) || headers))

    {:ok, {headers, session}}
  end

  # ⟦𓋰𓎄𓍤𓉞⟧ default_hyper_params :: auto-generated pointer for public function default_hyper_params
  def default_hyper_params(model, settings, session, context, options)

  def default_hyper_params(_model, _settings, _session, _context, _options) do
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
      hyper_param(name: :top_p)
    ]

    {:ok, x}
  end

  # ---------------------------------
  # prompt caching
  # ---------------------------------
  @max_cache_breakpoints 4

  # ⟦𓎙𓊝𓋹𓍯⟧ request_body :: auto-generated pointer for public function request_body
  def request_body(model, messages, tools, settings, session, context, options) do
    with {:ok, {body, session}} <-
           super(model, messages, tools, settings, session, context, options) do
      body =
        body
        |> apply_system_cache_control(settings)
        |> enforce_cache_breakpoint_cap()

      {:ok, {body, session}}
    end
  end

  # ⟦𓊃𓏏𓎛𓆑⟧ apply_system_cache_control :: Mark the system prompt as a cache breakpoint when the :cache_control setting is :ephemeral.
  defp apply_system_cache_control(body, settings) do
    enabled? =
      [
        settings[:settings],
        settings[:model_settings],
        settings[:provider_settings],
        settings[:config_settings]
      ]
      |> Enum.any?(&(&1 && &1[:cache_control] == :ephemeral))

    case {enabled?, body[:system]} do
      {true, text} when is_binary(text) ->
        Map.put(body, :system, [%{type: "text", text: text, cache_control: %{type: "ephemeral"}}])

      {true, blocks} when is_list(blocks) and blocks != [] ->
        {init, [last | rest]} = Enum.split(blocks, -1)

        last =
          if is_map(last) and not is_map_key(last, :cache_control),
            do: Map.put(last, :cache_control, %{type: "ephemeral"}),
            else: last

        Map.put(body, :system, init ++ [last | rest])

      _ ->
        body
    end
  end

  # ⟦𓍝𓎕𓋴𓇋⟧ enforce_cache_breakpoint_cap :: Anthropic allows at most 4 cache breakpoints; keep the first 4 and warn about the rest.
  defp enforce_cache_breakpoint_cap(%{system: system} = body) when is_list(system) do
    {system, used} = cap_blocks(system, 0)

    {messages, _} =
      Enum.map_reduce(body[:messages] || [], used, fn
        message, used when is_map(message) and is_list(message.content) ->
          {content, used} = cap_blocks(message.content, used)
          {%{message | content: content}, used}

        message, used ->
          {message, used}
      end)

    body
    |> Map.put(:messages, messages)
    |> Map.put(:system, system)
  end

  defp enforce_cache_breakpoint_cap(body) do
    {messages, _} =
      Enum.map_reduce(body[:messages] || [], 0, fn
        message, used when is_map(message) and is_list(message.content) ->
          {content, used} = cap_blocks(message.content, used)
          {%{message | content: content}, used}

        message, used ->
          {message, used}
      end)

    Map.put(body, :messages, messages)
  end

  defp cap_blocks(blocks, used) do
    Enum.map_reduce(blocks, used, fn
      block, used when is_map(block) and is_map_key(block, :cache_control) ->
        if used < @max_cache_breakpoints do
          {block, used + 1}
        else
          Logger.warning(
            "Anthropic prompt caching: more than #{@max_cache_breakpoints} cache breakpoints requested; dropping extras (keep the first #{@max_cache_breakpoints})."
          )

          {Map.delete(block, :cache_control), used}
        end

      block, used ->
        {block, used}
    end)
  end

  # ⟦𓍪𓈓𓍯𓊇⟧ completion_response :: auto-generated pointer for public function completion_response
  def completion_response(json, model, settings, session, context, options)

  def completion_response(json, model, settings, session, context, options) do
    with {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         %{
           id: id,
           model: model_name,
           stop_reason: _,
           content: _content
         } <- json do
      {:ok, choice} = completion_choices(id, json, model, settings, session, context, options)
      choices = [choice]
      prompt_tokens = json[:usage][:input_tokens] || 0
      completion_tokens = json[:usage][:output_tokens] || 0

      usage =
        GenAI.ChatCompletion.Usage.new(
          prompt_tokens: prompt_tokens,
          total_tokens: prompt_tokens + completion_tokens,
          completion_tokens: completion_tokens,
          cache_read_input_tokens: json[:usage][:cache_read_input_tokens],
          cache_creation_input_tokens: json[:usage][:cache_creation_input_tokens]
        )

      completion =
        GenAI.ChatCompletion.from_json(
          id: id,
          model: model_name,
          provider: provider,
          choices: choices,
          usage: usage
        )

      {:ok, completion}
    end
  end

  # ⟦𓆐𓅊𓎕𓋻⟧ completion_choices :: auto-generated pointer for public function completion_choices
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
      choice =
        GenAI.ChatCompletion.Choice.new(
          id: json.id,
          index: 0,
          message: message,
          finish_reason: json.stop_reason
        )

      {:ok, choice}
    end
  end

  # ⟦𓐢𓀥𓍡𓈸⟧ completion_choice :: auto-generated pointer for public function completion_choice
  def completion_choice(id, json, model, settings, session, context, options)

  def completion_choice(
        _,
        json = %{
          id: id,
          model: _,
          stop_reason: "tool_use",
          content: _content
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
          content: _content
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

  # ⟦𓈡𓊛𓋴𓊏⟧ completion_message :: auto-generated pointer for public function completion_message
  def completion_message(%{content: content}) when is_bitstring(content) do
    Enum.map([content], &completion_content/1)
  end

  def completion_message(%{content: content}) when is_list(content) do
    Enum.map(content, &completion_content/1)
  end

  # ⟦𓅔𓀐𓋆𓏯⟧ completion_content :: auto-generated pointer for public function completion_content
  def completion_content(json)

  def completion_content(%{id: id, type: "tool_use", name: tool_name, input: arguments}) do
    %GenAI.Message.Content.ToolUseContent{
      id: id,
      tool_name: tool_name,
      arguments: arguments
    }
  end

  def completion_content(%{type: "text", text: text} = json) do
    %GenAI.Message.Content.TextContent{
      system: false,
      type: :response,
      text: text,
      citations: json[:citations]
    }
  end

  def completion_content(%{type: "thinking"} = json) do
    %GenAI.Message.Content.ThinkingContent{
      thinking: json[:thinking],
      signature: json[:signature]
    }
  end

  def completion_content(%{type: "redacted_thinking"} = json) do
    %GenAI.Message.Content.RedactedThinkingContent{
      data: json[:data]
    }
  end

  def completion_content(%{type: "image"} = json) do
    media_types = %{
      "image/jpeg" => :jpeg,
      "image/png" => :png,
      "image/gif" => :gif,
      "image/webp" => :webp,
      "image/svg+xml" => :svg
    }

    %GenAI.Message.Content.ImageContent{
      source: :anthropic,
      type: media_types[json[:souce][:media_type]],
      resolution: :auto,
      resource: {:base64, json[:source][:data]},
      options: nil
    }
  end
end
