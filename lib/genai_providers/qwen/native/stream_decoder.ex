defmodule GenAI.Provider.Qwen.Native.StreamDecoder do
  @moduledoc "Decoder for incremental native DashScope SSE payloads."
  alias GenAI.Provider.Qwen.Native.Response, as: R

  def stream_event(json) do
    case chunk(json) do
      {:ok, openai} -> GenAI.StreamHandler.OpenAI.stream_event(openai)
      {:error, _} -> [{:finish, :error}]
    end
  end

  def chunk(json) do
    wire_result =
      if R.get(json, :code) in [nil, ""] && R.get(json, :status_code) in [nil, 200, "200"] &&
           is_map(R.get(json, :usage)) &&
           (is_nil(R.get(json, :output)) || R.get(R.get(json, :output), :choices) == []),
         do: {:ok, %{choices: [], usage: R.usage(R.get(json, :usage))}},
         else: R.wire(json)

    with {:ok, wire} <- wire_result,
         true <- Enum.all?(wire.choices, &valid_choice?/1) do
      choices =
        Enum.with_index(wire.choices)
        |> Enum.map(fn {choice, index} ->
          msg = R.get(choice, :message) || %{}

          %{
            index: index,
            delta: %{
              content: text(R.get(msg, :content)),
              reasoning_content: R.get(msg, :reasoning_content),
              tool_calls: calls(R.get(msg, :tool_calls))
            },
            finish_reason: R.finish(R.get(choice, :finish_reason))
          }
        end)

      {:ok, %{choices: choices, usage: wire.usage}}
    else
      false -> {:error, :unsupported_native_output_content}
      error -> error
    end
  end

  defp valid_choice?(choice) do
    msg = R.get(choice, :message)
    content = R.get(msg, :content)
    reasoning = R.get(msg, :reasoning_content)
    tools = R.get(msg, :tool_calls)

    is_map(msg) &&
      (is_nil(content) || is_binary(content) ||
         (is_list(content) &&
            Enum.all?(content, fn p -> is_map(p) && is_binary(R.get(p, :text)) end))) &&
      (is_nil(reasoning) || is_binary(reasoning)) &&
      (is_nil(tools) || (is_list(tools) && Enum.all?(tools, &is_map/1)))
  end

  defp text(parts) when is_list(parts), do: Enum.map_join(parts, "", &(R.get(&1, :text) || ""))
  defp text(text) when is_binary(text) or is_nil(text), do: text
  defp text(_), do: nil
  defp calls(nil), do: nil

  defp calls(calls) when is_list(calls) do
    Enum.with_index(calls)
    |> Enum.map(fn {call, index} ->
      function = R.get(call, :function) || %{}

      %{
        index: R.get(call, :index) || index,
        id: R.get(call, :id),
        type: R.get(call, :type),
        function: %{name: R.get(function, :name), arguments: R.get(function, :arguments)}
      }
    end)
  end

  defp calls(_), do: nil
end

defmodule GenAI.Provider.Qwen.Native.StreamHandler do
  @moduledoc false
  @behaviour GenAI.StreamHandler.Behaviour
  alias GenAI.Provider.Qwen.Native.{Response, SSE, StreamDecoder}

  def begin_stream(_, session, context, options) do
    options = Keyword.put(options || [], :stream_decoder, GenAI.StreamHandler.OpenAI)
    requested = options[:native_stream_handler]
    own_options = if requested, do: Keyword.delete(options, :stream_sink), else: options

    with {:ok, {{acc, _}, session}} <-
           GenAI.StreamHandler.Default.begin_stream(nil, session, context, own_options),
         {:ok, observer} <- observer(requested, session, context, options) do
      {:ok,
       {{%{
           acc: acc,
           framing: SSE.new(),
           observer: observer,
           request_id: nil,
           received_choice: false
         }, &handle_event/2}, session}}
    end
  end

  defp observer(nil, _, _, _), do: {:ok, nil}
  defp observer(__MODULE__, _, _, _), do: {:ok, nil}

  defp observer(handler, session, context, options) do
    with {:ok, {{state, callback}, _}} <-
           GenAI.StreamHandler.begin_stream(handler, session, context, options),
         do: {:ok, {state, callback}}
  end

  def handle_event({:data, chunk}, state) do
    {events, framing} = SSE.feed(state.framing, chunk)

    Enum.reduce_while(events, {:cont, %{state | framing: framing}}, fn frame, {:cont, state} ->
      cond do
        frame.event == "error" || (is_integer(frame.status) && frame.status != 200) ->
          error =
            if is_integer(frame.status),
              do: {:dashscope_stream_error, frame.status},
              else: :dashscope_stream_error

          {:halt, {:halt, %{state | acc: %{state.acc | error: error}}}}

        frame.event == "done" || frame.data == "[DONE]" ->
          {:cont, {:cont, %{state | acc: %{state.acc | completed: true}}}}

        frame.data != "" ->
          with {:ok, json} <- Jason.decode(frame.data),
               {:ok, converted} <- StreamDecoder.chunk(json) do
            state = %{
              state
              | request_id: Response.get(json, :request_id) || state.request_id,
                received_choice: state.received_choice || converted.choices != []
            }

            event = {:data, "data: " <> Jason.encode!(converted) <> "\n\n"}
            {action, state} = dispatch(event, state)
            if action == :halt, do: {:halt, {action, state}}, else: {:cont, {action, state}}
          else
            _ -> {:halt, {:halt, %{state | acc: %{state.acc | error: :dashscope_stream_error}}}}
          end

        true ->
          {:cont, {:cont, state}}
      end
    end)
  end

  def handle_event(event, state), do: dispatch(event, state)

  defp dispatch(event, state) do
    {action, acc} = GenAI.StreamHandler.Default.handle_event(event, state.acc)

    case state.observer do
      nil ->
        {action, %{state | acc: acc}}

      {observer, callback} ->
        {requested_action, observer} = callback.(event, observer)
        {requested_action, %{state | acc: acc, observer: {observer, callback}}}
    end
  end

  def finish(%{acc: %{error: error}}) when not is_nil(error), do: {:error, error}

  def finish(%{acc: %{status: status}}) when status != 200,
    do: {:error, {:dashscope_http_error, status}}

  def finish(state) do
    case handle_event({:data, "\n\n"}, state) do
      {_, %{acc: %{error: nil}} = state} ->
        if state.received_choice and (state.acc.completed or not is_nil(state.acc.finish)),
          do: completion(state),
          else: {:error, :incomplete_native_stream}

      {_, %{acc: %{error: error}}} ->
        {:error, error}
    end
  end

  defp completion(state) do
    acc = state.acc

    with {:ok, calls} <- assemble_calls(acc.tool_calls),
         {:ok, completion} <-
           Response.completion(
             %{
               request_id: state.request_id,
               output: %{
                 choices: [
                   %{
                     message: %{
                       role: "assistant",
                       content: acc.text,
                       reasoning_content: acc.thinking,
                       tool_calls: calls
                     },
                     finish_reason: acc.finish
                   }
                 ]
               },
               usage: %{
                 input_tokens: acc.usage && acc.usage[:prompt_tokens],
                 output_tokens: acc.usage && acc.usage[:completion_tokens],
                 total_tokens: acc.usage && acc.usage[:total_tokens]
               }
             },
             %GenAI.Model{model: acc.model, provider: acc.provider}
           ) do
      {:ok, %{acc | completed: true, completion: completion}}
    end
  end

  defp assemble_calls(groups) do
    groups = Enum.flat_map(groups, fn group -> if is_list(group), do: group, else: [group] end)

    groups
    |> Enum.reduce_while({:ok, %{}}, fn call, {:ok, acc} ->
      index = call[:index]
      function = call[:function] || %{}
      prev = Map.get(acc, index, %{id: nil, name: nil, arguments: ""})
      id = if call[:id] == "", do: nil, else: call[:id]
      name = if function[:name] == "", do: nil, else: function[:name]
      args = function[:arguments] || ""

      cond do
        not is_integer(index) || index < 0 || not is_binary(args) ->
          {:halt, {:error, :invalid_native_tool_call}}

        prev.id && id && prev.id != id ->
          {:halt, {:error, :invalid_native_tool_call}}

        prev.name && name && prev.name != name ->
          {:halt, {:error, :invalid_native_tool_call}}

        true ->
          {:cont,
           {:ok,
            Map.put(acc, index, %{
              id: id || prev.id,
              name: name || prev.name,
              arguments: prev.arguments <> args
            })}}
      end
    end)
    |> then(fn
      {:ok, calls} ->
        {:ok,
         calls
         |> Enum.sort_by(&elem(&1, 0))
         |> Enum.map(fn {_, c} ->
           %{id: c.id, type: "function", function: %{name: c.name, arguments: c.arguments}}
         end)}

      error ->
        error
    end)
  end
end

defmodule GenAI.Provider.Qwen.Native.SSE do
  @moduledoc false
  def new, do: %{buffer: "", frame: %{event: nil, status: nil, data: []}}
  def feed(state, chunk), do: lines(%{state | buffer: state.buffer <> chunk}, [])

  defp lines(state, events) do
    case :binary.match(state.buffer, "\n") do
      :nomatch ->
        {Enum.reverse(events), state}

      {offset, 1} ->
        <<line::binary-size(offset), _newline, rest::binary>> = state.buffer
        line = String.trim_trailing(line, "\r")
        state = %{state | buffer: rest}

        if line == "" do
          frame = %{state.frame | data: Enum.reverse(state.frame.data) |> Enum.join("\n")}
          lines(%{state | frame: new().frame}, [frame | events])
        else
          frame = field(state.frame, line)
          lines(%{state | frame: frame}, events)
        end
    end
  end

  defp field(frame, ":" <> _), do: frame

  defp field(frame, line) do
    case String.split(line, ":", parts: 2) do
      [key, value] ->
        value =
          if String.starts_with?(value, " "),
            do: binary_part(value, 1, byte_size(value) - 1),
            else: value

        case key do
          "data" ->
            %{frame | data: [value | frame.data]}

          "event" ->
            %{frame | event: value}

          "status" ->
            case Integer.parse(String.trim(value)) do
              {status, ""} -> %{frame | status: status}
              _ -> %{frame | status: -1}
            end

          _ ->
            frame
        end

      ["data"] ->
        %{frame | data: ["" | frame.data]}

      _ ->
        frame
    end
  end
end
