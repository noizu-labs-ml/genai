defmodule GenAI.QwenGenerationLiveTest do
  use ExUnit.Case, async: false
  @moduletag :live
  alias GenAI.Provider.Qwen
  alias GenAI.Message.Content

  defp value(candidates, label) do
    case Enum.find(candidates, &(is_binary(&1) && &1 != "" && &1 != "test-key")) do
      nil -> flunk("Unmet live prerequisite: " <> label)
      value -> value
    end
  end

  defp thread(style, prompt) do
    config = Application.get_env(:genai, :qwen, [])

    key =
      value(
        [config[:api_key], System.get_env("QWEN_API_KEY"), System.get_env("DASHSCOPE_API_KEY")],
        "Qwen API key"
      )

    base_key = if style == :native, do: :native_base_url, else: :base_url
    value([config[base_key]], "configured generation base")
    name = System.get_env("GENAI_LIVE_CHAT_MODEL") || "qwen-plus"
    model = if style == :native, do: Qwen.Models.native(name), else: Qwen.Models.model(name)

    GenAI.chat(:session)
    |> GenAI.with_model(model)
    |> GenAI.with_setting(:api_key, key)
    |> GenAI.with_setting(:enable_thinking, false)
    |> GenAI.with_setting(:max_tokens, 128)
    |> GenAI.with_message(GenAI.Message.user(prompt))
  end

  defp safe_ok(result, stage) do
    case result do
      {:ok, %Finch.Response{status: status}} when is_integer(status) ->
        flunk("#{stage}: HTTP #{status}")

      {:error, %Finch.Response{status: status}} when is_integer(status) ->
        flunk("#{stage}: HTTP #{status}")

      {:ok, value} ->
        value

      {:error, {tag, status}}
      when tag in [:http_error, :dashscope_http_error, :dashscope_stream_error] and
             is_integer(status) ->
        flunk("#{stage}: HTTP #{status}")

      _ ->
        flunk(stage <> ": failed (redacted)")
    end
  end

  defp completion(result, stage) do
    case safe_ok(result, stage) do
      {%GenAI.ChatCompletion{} = completion, _} -> completion
      _ -> flunk(stage <> ": invalid completion shape")
    end
  end

  defp stream_result(result, stage) do
    case safe_ok(result, stage) do
      {%{completion: %GenAI.ChatCompletion{}, error: nil} = acc, _} -> acc
      _ -> flunk(stage <> ": incomplete stream result")
    end
  end

  defp usage(completion, stage) do
    case completion.usage do
      %{prompt_tokens: p, completion_tokens: c, total_tokens: t}
      when is_integer(p) and p > 0 and is_integer(c) and c > 0 and is_integer(t) and t > 0 ->
        IO.puts("LIVE #{stage}: normalized usage total=#{t}")

      _ ->
        flunk(stage <> ": missing positive usage counts")
    end
  end

  for style <- [:compatible, :native] do
    @tag style: style, operation: :chat
    @tag if(style == :compatible, do: :compatible_chat, else: :native_chat)
    test "#{style} performs synthetic Qwen chat with normalized content and usage" do
      style = unquote(style)

      completed =
        completion(
          GenAI.run(thread(style, "Synthetic test: respond with the single word pong."), nil, []),
          "#{style} chat"
        )

      case completed.choices do
        [%{message: %{content: content}, finish_reason: reason} | _]
        when reason in [:stop, :end_turn] ->
          texts =
            if is_binary(content),
              do: [content],
              else: for(%Content.TextContent{text: text} <- List.wrap(content), do: text)

          if Enum.join(texts) == "", do: flunk("#{style} chat: no visible text")

        _ ->
          flunk("#{style} chat: missing successful completion")
      end

      usage(completed, "#{style} chat")
    end

    @tag style: style, operation: :tool_stream
    @tag if(style == :compatible, do: :compatible_tool_stream, else: :native_tool_stream)
    test "#{style} streams a synthetic function call with validated arguments" do
      style = unquote(style)

      tool =
        GenAI.Tool.new(
          name: "lookup_ticket",
          description: "Look up a synthetic ticket.",
          parameters: %{
            type: "object",
            properties: %{ticket_id: %{type: "string"}},
            required: ["ticket_id"]
          }
        )

      input =
        thread(style, "Call lookup_ticket for synthetic ticket T-1.")
        |> GenAI.with_tool(tool)
        |> GenAI.with_setting(:tool_choice, %{
          type: "function",
          function: %{name: "lookup_ticket"}
        })
        |> GenAI.with_stream_handler(%GenAI.StreamHandler.Accumulate{sink: self()})

      input =
        if style == :compatible,
          do: GenAI.with_setting(input, :stream_options, %{include_usage: true}),
          else: input

      acc = stream_result(GenAI.stream(input, nil, []), "#{style} tool stream")

      completed =
        if style == :native do
          acc.completion
        else
          if acc.tool_calls == [], do: flunk("compatible tool stream: no actual tool deltas")
          # Existing compatible API exposes raw deltas; validate strict assembly
          # without changing Core's published assistant-text completion shape.
          state = %{
            acc: acc,
            framing: GenAI.Provider.Qwen.Native.SSE.new(),
            observer: nil,
            request_id: nil
          }

          case GenAI.Provider.Qwen.Native.StreamHandler.finish(state) do
            {:ok, assembled} ->
              assembled.completion

            _ ->
              raw = Enum.flat_map(acc.tool_calls, fn x -> if is_list(x), do: x, else: [x] end)
              ids = Enum.count(raw, &(is_binary(&1[:id]) && &1[:id] != ""))

              names =
                Enum.count(
                  raw,
                  &(is_binary(get_in(&1, [:function, :name])) &&
                      get_in(&1, [:function, :name]) != "")
                )

              indices = Enum.all?(raw, &(is_integer(&1[:index]) && &1[:index] >= 0))

              flunk(
                "compatible tool stream: invalid assembly; fragments=#{length(raw)} nonempty_ids=#{ids} nonempty_names=#{names} indices_valid=#{indices}"
              )
          end
        end

      case completed.choices do
        [
          %{
            message: %GenAI.Message.ToolUsage{
              tool_calls: [%GenAI.Message.ToolCall{tool_name: "lookup_ticket", arguments: args}]
            }
          }
          | _
        ] ->
          if (args["ticket_id"] || args[:ticket_id]) != "T-1",
            do: flunk("#{style} tool stream: incorrect synthetic ticket argument")

        _ ->
          flunk("#{style} tool stream: missing assembled tool invocation")
      end

      usage(completed, "#{style} tool stream")
    end
  end
end
