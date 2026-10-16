defmodule GenAI.Provider.Qwen.Native.Response do
  @moduledoc false
  def get(map, key) when is_map(map), do: Map.get(map, key, Map.get(map, Atom.to_string(key)))
  def get(_, _), do: nil

  def wire(json) when is_map(json) do
    code = get(json, :code)
    output = get(json, :output)

    cond do
      code not in [nil, ""] ->
        {:error, :dashscope_api_error}

      get(json, :status_code) not in [nil, 200, "200"] ->
        {:error, :dashscope_api_error}

      is_map(output) ->
        choices =
          get(output, :choices) ||
            if(is_binary(get(output, :text)),
              do: [
                %{
                  message: %{role: "assistant", content: get(output, :text)},
                  finish_reason: get(output, :finish_reason)
                }
              ]
            )

        if is_list(choices) && choices != [] do
          {:ok, %{id: get(json, :request_id), choices: choices, usage: usage(get(json, :usage))}}
        else
          {:error, :invalid_native_output}
        end

      true ->
        {:error, :invalid_native_output}
    end
  end

  def wire(_), do: {:error, :invalid_native_output}

  def completion(json, model) do
    with {:ok, wire} <- wire(json),
         {:ok, choices} <-
           GenAI.Provider.Qwen.Native.Messages.collect(Enum.with_index(wire.choices), fn {choice,
                                                                                          index} ->
             with {:ok, message} <- message(get(choice, :message)) do
               {:ok,
                GenAI.ChatCompletion.Choice.new(
                  index: index,
                  message: message,
                  finish_reason: finish(get(choice, :finish_reason))
                )}
             end
           end) do
      {:ok,
       GenAI.ChatCompletion.from_json(
         id: wire.id,
         model: model.model,
         provider: model.provider,
         choices: choices,
         usage: GenAI.ChatCompletion.Usage.new(wire.usage)
       )}
    end
  end

  def message(json) when is_map(json) do
    with "assistant" <- get(json, :role),
         {:ok, content} <- content(get(json, :content)),
         {:ok, calls} <-
           GenAI.Provider.Qwen.Native.Messages.collect(get(json, :tool_calls) || [], &call/1) do
      reasoning = get(json, :reasoning_content)

      parts =
        if is_binary(reasoning) && reasoning != "",
          do: [%GenAI.Message.Content.ThinkingContent{thinking: reasoning} | content],
          else: content

      if calls == [],
        do: {:ok, GenAI.Message.assistant(parts)},
        else:
          {:ok, GenAI.Message.ToolUsage.new(role: :assistant, content: parts, tool_calls: calls)}
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_native_message}
    end
  end

  def message(_), do: {:error, :invalid_native_message}
  defp content(nil), do: {:ok, []}
  defp content(""), do: {:ok, []}

  defp content(text) when is_binary(text),
    do: {:ok, [%GenAI.Message.Content.TextContent{text: text}]}

  defp content(parts) when is_list(parts) do
    GenAI.Provider.Qwen.Native.Messages.collect(parts, fn part ->
      case get(part, :text) do
        text when is_binary(text) -> {:ok, %GenAI.Message.Content.TextContent{text: text}}
        _ -> {:error, :unsupported_native_output_content}
      end
    end)
  end

  defp content(_), do: {:error, :invalid_native_message}

  defp call(call) do
    function = get(call, :function)

    with id when is_binary(id) <- get(call, :id),
         "function" <- get(call, :type),
         name when is_binary(name) <- get(function, :name),
         arguments when is_binary(arguments) <- get(function, :arguments),
         {:ok, args} when is_map(args) <- Jason.decode(arguments) do
      {:ok, %GenAI.Message.ToolCall{id: id, type: :function, tool_name: name, arguments: args}}
    else
      _ -> {:error, :invalid_native_tool_call}
    end
  end

  def usage(usage) do
    Enum.reduce(
      [
        {:input_tokens, :prompt_tokens},
        {:output_tokens, :completion_tokens},
        {:total_tokens, :total_tokens}
      ],
      %{},
      fn {wire, core}, acc ->
        case get(usage, wire) do
          value when is_integer(value) and value >= 0 -> Map.put(acc, core, value)
          _ -> acc
        end
      end
    )
  end

  # Never pass unknown finish reasons to Core's String.to_atom fallback.
  def finish(reason) when reason in [nil, "", "null"], do: nil

  def finish(reason) when reason in [:stop, :max_tokens, :tool_call, :content_filter, :unknown],
    do: reason

  def finish("stop"), do: :stop
  def finish("length"), do: :max_tokens
  def finish("tool_calls"), do: :tool_call
  def finish("function_call"), do: :tool_call
  def finish("content_filter"), do: :content_filter
  def finish(_), do: :unknown
end
