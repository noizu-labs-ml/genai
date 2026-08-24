defmodule GenAI.Provider.Qwen.Encoder do
  @base_url "https://dashscope-intl.aliyuncs.com/compatible-mode/v1"
  use GenAI.Model.EncoderBehaviour

  # ⟦𓊛𓇋𓎦𓉐𓍕⟧ stream_decoder :: Decode OpenAI compatible chat.completion.chunk SSE streams.
  def stream_decoder, do: GenAI.StreamHandler.OpenAI

  @doc "Runtime base_url from `config :genai, :qwen, base_url:` (DashScope compatible-mode /v1)."
  # ⟦𓈀𓋛𓀊𓄪⟧ base_url :: Runtime base_url from config.
  def base_url, do: GenAI.Provider.MediaHelpers.base_url(:qwen, @base_url)

  # DashScope compatible-mode is already versioned at `/compatible-mode/v1`, so chat is
  # `/chat/completions` (not the EncoderBehaviour default `/v1/chat/completions`).
  # ⟦𓍗𓈁𓁣𓈶⟧ endpoint :: auto-generated pointer for public function endpoint
  def endpoint(_model, _settings, session, _context, _options),
    do: {:ok, {{:post, "#{base_url()}/chat/completions"}, session}}

  # ⟦𓇦𓉀𓁗𓈳⟧ default_hyper_params :: auto-generated pointer for public function default_hyper_params
  def default_hyper_params(model, settings, session, context, options)

  def default_hyper_params(_model, _settings, _session, _context, _options) do
    x = [
      hyper_param(name: :frequency_penalty),
      hyper_param(name: :logit_bias),
      hyper_param(name: :logprobs),
      hyper_param(name: :max_tokens, type: :integer),
      hyper_param(name: :max_completion_tokens, type: :integer),
      hyper_param(name: :metadata),
      hyper_param(name: :completion_choices, as: :n),
      hyper_param(name: :parallel_tool_calls, type: :boolean),
      hyper_param(name: :presence_penalty),
      hyper_param(name: :response_format),
      hyper_param(name: :seed),
      hyper_param(name: :stop_sequence, as: :stop, type: :list),
      hyper_param(name: :stream, type: :boolean),
      hyper_param(name: :stream_options),
      hyper_param(name: :temperature),
      hyper_param(
        name: :tool_choice,
        type: :string,
        sentinel: fn _, body, _, _ -> body[:tools] && true end
      ),
      hyper_param(name: :top_logprobs),
      hyper_param(name: :top_p),
      hyper_param(name: :user),
      # DashScope / Qwen thinking controls (qwen3.8-max thinks by default).
      hyper_param(name: :enable_thinking, type: :boolean),
      hyper_param(name: :reasoning_effort),
      hyper_param(name: :thinking_budget, type: :integer)
    ]

    {:ok, x}
  end

  # ⟦𓉸𓐂𓆥𓁫⟧ completion_choice :: Parse assistant content, including DashScope reasoning_content.
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
      )
      when is_list(tool_calls) do
    tool_calls =
      tool_calls
      |> Enum.map(fn
        %{
          id: id,
          type: "function",
          function: %{name: name, arguments: arguments_json}
        } = _call ->
          arguments =
            case Jason.decode(arguments_json, keys: :atoms) do
              {:ok, arguments} ->
                arguments

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

    content =
      [
        json[:reasoning_content] &&
          %GenAI.Message.Content.ThinkingContent{thinking: json[:reasoning_content]},
        json[:content] && %GenAI.Message.Content.TextContent{text: json[:content]}
      ]
      |> Enum.reject(&is_nil/1)
      |> then(fn
        [] -> nil
        x -> x
      end)

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
      )
      when is_binary(reasoning_content) and reasoning_content != "" do
    parts =
      [
        %GenAI.Message.Content.ThinkingContent{thinking: reasoning_content},
        content && content != "" && %GenAI.Message.Content.TextContent{text: content}
      ]
      |> Enum.reject(&(&1 == false or is_nil(&1)))

    msg = GenAI.Message.assistant(parts)
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
