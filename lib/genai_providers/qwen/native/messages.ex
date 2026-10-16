defmodule GenAI.Provider.Qwen.Native.Messages do
  @moduledoc false
  alias GenAI.Message.Content

  def encode(%GenAI.Message.ToolResponse{} = msg) do
    with {:ok, content} <- json_text(msg.tool_response) do
      {:ok, %{role: "tool", tool_call_id: msg.tool_call_id, content: content}}
    end
  end

  def encode(%GenAI.Message.ToolUsage{} = msg) do
    with {:ok, base} <- message(msg.role, msg.content),
         {:ok, calls} <- collect(msg.tool_calls || [], &tool_call/1) do
      existing = base[:tool_calls] || []
      {:ok, Map.put(base, :tool_calls, Enum.uniq_by(existing ++ calls, & &1.id))}
    end
  end

  def encode(%GenAI.Message{} = msg), do: message(msg.role, msg.content)
  def encode(_), do: {:error, :unsupported_native_message}

  defp json_text(text) when is_binary(text), do: {:ok, text}

  defp json_text(value) do
    case Jason.encode(value) do
      {:ok, encoded} -> {:ok, encoded}
      _ -> {:error, :invalid_native_tool_result}
    end
  end

  defp message(role, content) when role in [:system, :user, :assistant, :tool] do
    parts = if is_list(content), do: content, else: [content]

    with {:ok, parts} <- collect(parts, &part/1) do
      calls = for {:call, c} <- parts, do: c
      reasoning = for {:thinking, t} <- parts, do: t
      body = for {:body, p} <- parts, do: p

      body =
        case body do
          [%{text: t}] -> t
          [] -> ""
          values -> values
        end

      base = %{role: Atom.to_string(role), content: body}
      base = if calls == [], do: base, else: Map.put(base, :tool_calls, calls)

      {:ok,
       if(reasoning == [],
         do: base,
         else: Map.put(base, :reasoning_content, Enum.join(reasoning, "\n"))
       )}
    end
  end

  defp message(_, _), do: {:error, :unsupported_native_role}

  defp part(nil), do: {:ok, {:body, %{text: ""}}}
  defp part(text) when is_binary(text), do: {:ok, {:body, %{text: text}}}
  defp part(%Content.TextContent{text: text}) when is_binary(text), do: part(text)

  defp part(%Content.ThinkingContent{thinking: text}) when is_binary(text),
    do: {:ok, {:thinking, text}}

  defp part(%Content.ImageContent{resource: {:uri, url}}) when is_binary(url),
    do: {:ok, {:body, %{image: url}}}

  defp part(%Content.ImageContent{resource: {:base64, bytes}, type: type})
       when is_binary(bytes) and type in [:png, :jpeg, :jpg, :webp, :gif] do
    mime = if type == :jpg, do: "jpeg", else: Atom.to_string(type)
    {:ok, {:body, %{image: "data:image/#{mime};base64,#{bytes}"}}}
  end

  defp part(%GenAI.Message.ToolCall{} = call), do: wrap_call(call)
  defp part(%Content.ToolUseContent{} = call), do: wrap_call(call)
  defp part(%Content.AudioContent{}), do: {:error, :unsupported_native_audio_content}
  defp part(_), do: {:error, :unsupported_native_content}
  defp wrap_call(call), do: with({:ok, encoded} <- tool_call(call), do: {:ok, {:call, encoded}})

  defp tool_call(%{id: id, tool_name: name, arguments: args})
       when is_binary(id) and is_binary(name) do
    case Jason.encode(args) do
      {:ok, json} -> {:ok, %{id: id, type: "function", function: %{name: name, arguments: json}}}
      _ -> {:error, :invalid_native_tool_call}
    end
  end

  defp tool_call(_), do: {:error, :invalid_native_tool_call}

  def for_api(messages, api, preserve?) do
    collect(messages, fn message ->
      if is_map(message) do
        content = message[:content]
        parts = if is_list(content), do: content, else: [%{text: content || ""}]

        cond do
          Enum.any?(parts, &(is_map(&1) && Map.has_key?(&1, :image))) && api == "text" ->
            {:error, :multimodal_model_required}

          Enum.any?(parts, &(not is_map(&1) || Map.keys(&1) -- [:text, :image] != [])) ->
            {:error, :unsupported_native_content}

          true ->
            message = if preserve?, do: message, else: Map.delete(message, :reasoning_content)

            message =
              cond do
                api == "multimodal" && message[:role] != "tool" ->
                  Map.put(message, :content, parts)

                api == "text" ->
                  Map.put(message, :content, Enum.map_join(parts, "\n", & &1.text))

                true ->
                  message
              end

            {:ok, message}
        end
      else
        {:error, :unsupported_native_message}
      end
    end)
  end

  def collect(values, mapper) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, acc} ->
      case mapper.(value) do
        {:ok, encoded} -> {:cont, {:ok, [encoded | acc]}}
        error -> {:halt, error}
      end
    end)
    |> then(fn
      {:ok, values} -> {:ok, Enum.reverse(values)}
      error -> error
    end)
  end
end
