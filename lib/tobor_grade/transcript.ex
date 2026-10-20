defmodule ToborGrade.Transcript do
  @moduledoc """
  Transcript loading for `tobor-grade`.

  A transcript is a JSONL file (one event per line, Claude Code session
  shape: `{"type": "user"|"assistant", "message": {"content": ...}}`).
  Walking back drops the newest real user turn — a `user` event whose
  content is not solely tool results — and everything after it.
  """

  @type event :: %{required(:type) => String.t(), required(:rendered) => String.t()}
  @type t :: [event()]

  @doc "Parse a JSONL transcript; blank lines are skipped, anything else fails fast."
  @spec load(Path.t()) :: {:ok, t()} | {:error, term()}
  def load(path) do
    case File.read(path) do
      {:ok, body} -> parse(body)
      {:error, reason} -> {:error, {:transcript_read, path, reason}}
    end
  end

  @doc "Parse transcript JSONL from a string."
  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(body) when is_binary(body) do
    lines =
      body
      |> String.split(["\r\n", "\n"])
      |> Enum.with_index(1)
      |> Enum.reject(fn {line, _} -> String.trim(line) == "" end)

    events =
      Enum.reduce_while(lines, {:ok, []}, fn {line, n}, {:ok, acc} ->
        case Jason.decode(line) do
          {:ok, map} when is_map(map) ->
            {:cont,
             {:ok,
              [
                %{
                  type: map["type"] |> to_string(),
                  rendered: render_event(map),
                  user_turn: user_turn?(map)
                }
                | acc
              ]}}

          {:ok, _} ->
            {:halt, {:error, {:invalid_transcript_line, n}}}

          {:error, _} ->
            {:halt, {:error, {:invalid_transcript_line, n}}}
        end
      end)

    case events do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      error -> error
    end
  end

  def parse(_), do: {:error, :invalid_transcript}

  @doc "Render a transcript's events to plain text for classifier input."
  @spec render(t()) :: String.t()
  def render(events) when is_list(events) do
    events
    |> Enum.map(& &1.rendered)
    |> Enum.reject(&(&1 == "" or is_nil(&1)))
    |> Enum.join("\n\n")
  end

  @doc """
  Drop the newest `count` real user turns (and their aftermath).

  Returns `{:ok, trimmed, remaining_turns}` or `{:error, :cannot_walk_back}`
  when fewer than `count + 1` user turns exist (the first turn is never
  dropped — a transcript with no context left cannot be walked back).
  """
  @spec walk_back(t(), non_neg_integer()) ::
          {:ok, t(), non_neg_integer()} | {:error, :cannot_walk_back}
  def walk_back(events, count) when is_list(events) and is_integer(count) and count >= 0 do
    turn_starts =
      events
      |> Enum.with_index()
      |> Enum.filter(fn {event, _} -> event.user_turn end)
      |> Enum.map(fn {_, i} -> i end)

    total = length(turn_starts)
    keep = total - count

    if keep >= 1 do
      cut_at = Enum.at(turn_starts, keep)
      {:ok, Enum.take(events, cut_at || length(events)), keep}
    else
      {:error, :cannot_walk_back}
    end
  end

  def walk_back(_, _), do: {:error, :cannot_walk_back}

  # A real user turn is a user event carrying at least one non-tool-result
  # content part; pure tool_result echoes are user-role but not user turns.
  defp user_turn?(%{"type" => "user", "message" => %{"content" => content}}) do
    case content do
      text when is_binary(text) -> String.trim(text) != ""
      blocks when is_list(blocks) -> Enum.any?(blocks, &text_block?/1)
      _ -> false
    end
  end

  defp user_turn?(_), do: false

  defp text_block?(%{"type" => "text", "text" => text}) when is_binary(text),
    do: String.trim(text) != ""

  defp text_block?(_), do: false

  defp render_event(%{"type" => type, "message" => %{"content" => content}} = event)
       when type in ["user", "assistant"] do
    role = if type == "user", do: "user", else: "assistant"
    "#{role}: #{render_content(content, event)}"
  end

  defp render_event(%{"type" => type} = event) when is_binary(type) do
    case render_content(event["message"] && event["message"]["content"], event) do
      "" -> ""
      text -> "#{type}: #{text}"
    end
  end

  defp render_event(_), do: ""

  defp render_content(content, _event) when is_binary(content), do: String.trim(content)

  defp render_content(blocks, _event) when is_list(blocks) do
    blocks
    |> Enum.map(&render_block/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end

  defp render_content(_content, event), do: compact(event["message"] || %{})

  defp render_block(%{"type" => "text", "text" => text}) when is_binary(text),
    do: String.trim(text)

  defp render_block(%{"type" => "tool_use", "name" => name}) when is_binary(name),
    do: "[tool call: #{name}]"

  defp render_block(%{"type" => "tool_result"} = block) do
    case block["content"] do
      text when is_binary(text) and text != "" -> "[tool result: #{truncate(text)}]"
      _ -> "[tool result]"
    end
  end

  defp render_block(%{"type" => other} = block) when is_binary(other),
    do: "[#{other}: #{truncate(compact(block))}]"

  defp render_block(_), do: ""

  defp compact(map) when is_map(map), do: map |> Jason.encode!() |> truncate()
  defp compact(other), do: other |> to_string() |> truncate()

  defp truncate(text, max \\ 400) do
    text = String.replace(text, "\n", " ")

    if String.length(text) > max,
      do: String.slice(text, 0, max) <> "…",
      else: text
  end
end
