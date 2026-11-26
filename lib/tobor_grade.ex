defmodule ToborGrade do
  @moduledoc """
  〚📦:3e519f70-8fbf-5b7d-ad06-1ebd4a621858〛 tobor grade :: Transcript grading CLI for the component-eval platform (Jev/Alibaba verdicts, walkback retries, jsonl sink).

  `tobor-grade` — transcript grading CLI for the component-eval platform.

  Wraps `GenAI.Classifier.Router.classify/2` (Core 0.4.0):

  - default lane: hosted Jev (`GenAI.Provider.Jev.Models.latest/0`, model
    `jev-latest` via TypeSafe) answering one `:choice` question —
    `continuation | topic-switch | new-task | more-context-needed`.
  - `--score`: Alibaba's decision model (`GenAI.Provider.Qwen.Models.decision_model/0`,
    GA id `decision-model`) answering one 0-100 `:score` question. The SystemOne
    adapter's inferred `:alibaba_rounded_hundredths` distribution policy applies
    automatically to decision-model requests (the retired `decision-model-preview`
    id is still recognised); it is reused here, never re-implemented.
  - `--walkback N` (cap 5): when the verdict is `more-context-needed`, walk the
    transcript back one user turn and re-grade, up to N times.
  - `--sink jsonl:<path>`: append one JSON line
    `{component?, verdict, score?, transcript_path, walkback_used, timestamp}`.
  - Recursion guard: when `TOBOR_GRADING=1` is set in the environment, grading
    refuses to run again (a grading session must not grade itself).
  """

  @walkback_cap 5
  # Every classifier call sends at most this many characters (graphemes) of
  # rendered transcript — never a whole session or a dataset. Oversized input
  # keeps the head and the tail with a single omission marker between them.
  @input_cap_chars 6_000
  # Head/tail split of the cap minus the marker reserve, in characters
  # (graphemes); cuts are grapheme-aligned, so no cut ever splits a UTF-8
  # codepoint, and head + marker + tail always fits the cap.
  @input_cap_marker_max_chars 64
  @input_cap_head_chars div(@input_cap_chars - @input_cap_marker_max_chars, 2)
  @input_cap_tail_chars @input_cap_chars - @input_cap_marker_max_chars - @input_cap_head_chars
  # The tail is cut from one byte window at the end (never a walk from the
  # start): about 8 bytes per wanted grapheme, moved forward to a codepoint
  # boundary and walked once; if it holds fewer graphemes than wanted (long
  # clusters), widen it by a factor up to a byte ceiling and keep what it
  # holds at the ceiling.
  @input_cap_tail_window_bytes 8 * @input_cap_tail_chars
  @input_cap_tail_window_widen_factor 4
  @input_cap_tail_window_max_bytes 32 * @input_cap_tail_chars
  @verdicts ["continuation", "topic-switch", "new-task", "more-context-needed"]
  @walkback_verdict "more-context-needed"

  alias GenAI.Classifier.{Question, Request}
  alias ToborGrade.Transcript

  @type verdict :: String.t()

  # ---------------------------------------------------------------------------
  # Entry point
  # ---------------------------------------------------------------------------

  @doc """
  Run the CLI. `argv` is the raw argument list; `opts` carries internal
  injection points (`:router`, `:now`) used by tests.
  """
  @spec run([String.t()], keyword()) ::
          {:ok, map()} | {:error, term()}
  def run(argv, opts \\ []) when is_list(argv) and is_list(opts) do
    with :ok <- recursion_guard(),
         {:ok, args} <- parse_args(argv),
         {:ok, events} <- Transcript.load(args.transcript_path) do
      grade_loop(events, args, opts)
    end
  end

  # ---------------------------------------------------------------------------
  # Recursion guard
  # ---------------------------------------------------------------------------

  defp recursion_guard do
    case System.get_env("TOBOR_GRADING") do
      flag when flag in ["1", "true"] -> {:error, :grading_recursion_guard}
      _ -> :ok
    end
  end

  # ---------------------------------------------------------------------------
  # Arguments
  # ---------------------------------------------------------------------------

  defp parse_args(argv) do
    {opts, extra, invalid} =
      OptionParser.parse(argv,
        strict: [
          transcript: :string,
          sink: :string,
          walkback: :integer,
          score: :boolean,
          component: :string
        ]
      )

    cond do
      invalid != [] -> {:error, {:unknown_arguments, invalid}}
      extra != [] -> {:error, {:unexpected_arguments, extra}}
      true -> validate_args(opts)
    end
  end

  defp validate_args(opts) do
    with {:ok, transcript_path} <- require_path(Keyword.get(opts, :transcript), :transcript),
         {:ok, sink_path} <- require_sink(Keyword.get(opts, :sink)),
         :ok <- validate_walkback(Keyword.get(opts, :walkback, 0)) do
      {:ok,
       %{
         transcript_path: transcript_path,
         sink_path: sink_path,
         walkback_max: min(Keyword.get(opts, :walkback, 0), @walkback_cap),
         score?: Keyword.get(opts, :score, false),
         component: Keyword.get(opts, :component)
       }}
    end
  end

  defp require_path(nil, flag), do: {:error, {:missing_argument, flag}}
  defp require_path(path, _flag) when is_binary(path), do: {:ok, path}
  defp require_path(_, flag), do: {:error, {:invalid_argument, flag}}

  defp require_sink(nil), do: {:error, {:missing_argument, :sink}}

  defp require_sink("jsonl:" <> path) when byte_size(path) > 0, do: {:ok, path}
  defp require_sink(_), do: {:error, {:invalid_sink, "only jsonl:<path> sinks are supported"}}

  defp validate_walkback(n) when is_integer(n) and n >= 0 and n <= @walkback_cap, do: :ok

  defp validate_walkback(n) when is_integer(n),
    do: {:error, {:invalid_walkback, {:cap, @walkback_cap}}}

  defp validate_walkback(n), do: {:error, {:invalid_walkback, n}}

  # ---------------------------------------------------------------------------
  # Grading loop (with more-context-needed walk-back)
  # ---------------------------------------------------------------------------

  defp grade_loop(events, args, opts) do
    do_grade_loop(events, args, opts, 0, nil)
  end

  defp do_grade_loop(events, args, opts, walkback_used, last_outcome) do
    input = Transcript.render(events)

    with {:ok, request} <- build_request(input, args),
         {:ok, result} <- classify(request, args, opts),
         {:ok, outcome} <- extract(args, result) do
      if outcome.verdict == @walkback_verdict and walkback_used < args.walkback_max do
        case Transcript.walk_back(events, 1) do
          {:ok, trimmed, _} ->
            do_grade_loop(trimmed, args, opts, walkback_used + 1, {:ok, outcome})

          {:error, :cannot_walk_back} ->
            finish({:ok, outcome}, args, opts, walkback_used)
        end
      else
        finish({:ok, outcome}, args, opts, walkback_used)
      end
    else
      # A failed retry keeps the last good outcome so one flaky call does not
      # discard an earlier verdict; with no earlier outcome the error surfaces.
      {:error, reason} ->
        case last_outcome do
          {:ok, outcome} -> finish({:ok, outcome}, args, opts, walkback_used)
          nil -> {:error, reason}
        end
    end
  end

  defp classify(request, _args, opts) do
    case Keyword.get(opts, :router, GenAI.Classifier.Router) do
      router when is_function(router, 1) -> router.(request)
      router -> router.classify(request)
    end
  end

  defp finish(outcome, args, opts, walkback_used) do
    with {:ok, outcome} <- outcome,
         :ok <- write_sink(args, outcome, walkback_used, opts) do
      summary =
        outcome
        |> Map.put(:walkback_used, walkback_used)
        |> Map.put(:transcript_path, args.transcript_path)

      {:ok, summary}
    end
  end

  # ---------------------------------------------------------------------------
  # Classifier requests
  # ---------------------------------------------------------------------------

  @doc "Build the classifier request for one rendered transcript input. Input longer than `input_cap_chars/0` characters is truncated, keeping the head and the tail at codepoint boundaries with a single `[N or more characters omitted]` marker between them (the count is a truthful lower bound — the overshoot walk stops within cap + 1 steps and never counts the whole input); head + marker + tail always stays within the cap."
  @spec build_request(String.t(), %{score?: boolean(), component: String.t() | nil}) ::
          {:ok, map()} | {:error, term()}
  def build_request(input, args) when is_binary(input) do
    input = capped_input(input)

    if args.score?, do: score_request(input), else: choice_request(input)
  end

  # Deterministic head+tail truncation counted in characters (graphemes):
  # keep the head and the tail with one "[N or more characters omitted]"
  # marker between them, never send a huge dataset. The overshoot decision
  # stops after cap + 1 graphemes and never counts the whole input, so the
  # marker count is a truthful lower bound (cap + 1 minus the graphemes
  # kept in head and tail); the tail comes from one bounded byte window at
  # the end, never a walk from the start.
  defp capped_input(input) do
    case grapheme_census(input, 0, []) do
      {:within_cap, _count} ->
        input

      {:over_cap, head_graphemes} ->
        tail_graphemes = tail_graphemes(input)
        tail = Enum.join(tail_graphemes)
        omitted = @input_cap_chars + 1 - @input_cap_head_chars - length(tail_graphemes)
        head = Enum.reverse(head_graphemes) |> Enum.join("")
        marker = "[#{omitted} or more characters omitted]"

        head <> marker <> tail
    end
  end

  # Walk graphemes with String.next_grapheme/1, keeping the first
  # @input_cap_head_chars graphemes as the head. Returns as soon as the
  # count passes @input_cap_chars — at most cap + 1 steps, whether the
  # input is 6 KB or 6 MB — and never scans the whole input: within-cap
  # inputs simply run out of graphemes first.
  defp grapheme_census(rest, count, head_acc) do
    case String.next_grapheme(rest) do
      nil ->
        {:within_cap, count}

      {grapheme, rest} ->
        count = count + 1
        head_acc = if count <= @input_cap_head_chars, do: [grapheme | head_acc], else: head_acc

        if count > @input_cap_chars do
          {:over_cap, head_acc}
        else
          grapheme_census(rest, count, head_acc)
        end
    end
  end

  # The tail, from one byte window at the end of the input: cut ~8 bytes
  # per wanted grapheme off the end, move the window's start forward to a
  # codepoint boundary, walk just that window once. If it holds fewer
  # graphemes than wanted (long clusters), widen it by
  # @input_cap_tail_window_widen_factor up to @input_cap_tail_window_max_bytes
  # and keep whatever it holds at the ceiling — a truthful tail lower bound.
  defp tail_graphemes(input) do
    limit = min(@input_cap_tail_window_max_bytes, byte_size(input))
    do_tail_graphemes(input, min(@input_cap_tail_window_bytes, limit), limit)
  end

  defp do_tail_graphemes(input, bytes, limit) do
    window = codepoint_aligned(binary_part(input, byte_size(input) - bytes, bytes))
    graphemes = window_graphemes(window, [])

    if length(graphemes) >= @input_cap_tail_chars or bytes >= limit do
      # The walk accumulated reversed, so its first N entries are the
      # window's LAST N graphemes — reverse them into input order.
      graphemes |> Enum.take(@input_cap_tail_chars) |> Enum.reverse()
    else
      do_tail_graphemes(input, bytes * @input_cap_tail_window_widen_factor, limit)
    end
  end

  # Move the window's start forward to a codepoint boundary: a byte cut
  # from the end may land inside a multi-byte character, so drop leading
  # bytes until the window is valid UTF-8 (at most 3 bytes).
  defp codepoint_aligned(bin) do
    if String.valid?(bin) do
      bin
    else
      codepoint_aligned(binary_part(bin, 1, byte_size(bin) - 1))
    end
  end

  # Walk one bounded window into a reversed grapheme list.
  defp window_graphemes(rest, acc) do
    case String.next_grapheme(rest) do
      nil -> acc
      {grapheme, rest} -> window_graphemes(rest, [grapheme | acc])
    end
  end

  defp choice_request(input) do
    question = %Question{
      id: "verdict",
      type: :choice,
      choices: @verdicts,
      instructions:
        "Classify the latest turn of this coding-agent transcript. " <>
          "continuation: work proceeds within the task already underway. " <>
          "topic-switch: same session, but the focus changed to a different subject. " <>
          "new-task: a fresh task begins. " <>
          "more-context-needed: the excerpt lacks the context needed to decide. " <>
          "Answer with exactly one choice id."
    }

    request(%{input: input, questions: [question]}, GenAI.Provider.Jev.Models.latest())
  end

  defp score_request(input) do
    rubric =
      Enum.map(0..9, fn i ->
        score = i * 100 / 9

        %{
          id: "level-#{i}",
          label: "#{round(score)} — component-work quality level #{i} of 9",
          score: score
        }
      end)

    question = %Question{
      id: "quality",
      type: :score,
      rubric: rubric,
      instructions:
        "Rate the component-work quality of the latest turn on a 0-100 scale. " <>
          "Pick the rubric level that best matches the transcript."
    }

    request(
      %{input: input, questions: [question]},
      GenAI.Provider.Qwen.Models.decision_model()
    )
  end

  defp request(base, model), do: Request.normalize(Map.put(base, :model, model))

  @doc "The ordered verdict choice ids."
  @spec verdicts() :: [verdict(), ...]
  def verdicts, do: @verdicts

  @doc "Maximum --walkback value accepted."
  @spec walkback_cap() :: pos_integer()
  def walkback_cap, do: @walkback_cap

  @doc """
  Maximum characters (graphemes) of rendered transcript one classifier call
  sends (applied in `build_request/2`). Oversized input keeps the head and
  the tail with a single `[N or more characters omitted]` marker between
  them; the overshoot decision walks at most cap + 1 graphemes and never
  counts the whole input (the marker count is a truthful lower bound), the
  tail is cut from one bounded byte window at the end (never a walk from
  the start), and head + marker + tail always stays within this cap.
  """
  @spec input_cap_chars() :: pos_integer()
  def input_cap_chars, do: @input_cap_chars

  # ---------------------------------------------------------------------------
  # Result extraction
  # ---------------------------------------------------------------------------

  defp extract(args, result) do
    question_id = if args.score?, do: "quality", else: "verdict"

    input_tokens =
      case result.usage do
        %{input_tokens: t} when is_integer(t) -> t
        %{"input_tokens" => t} when is_integer(t) -> t
        _ -> nil
      end

    with answer when not is_nil(answer) <-
           Enum.find(result.answers, &(&1.question_id == question_id)) do
      if args.score? do
        score =
          case answer.expected_score do
            nil -> nil
            number -> Float.round(number * 1.0, 1)
          end

        {:ok, %{verdict: answer.grade || "ungraded", score: score, input_tokens: input_tokens}}
      else
        verdict = answer.choice_id || answer.value
        {:ok, %{verdict: verdict, score: nil, input_tokens: input_tokens}}
      end
    else
      nil -> {:error, {:missing_answer, question_id}}
    end
  end

  # ---------------------------------------------------------------------------
  # Sink
  # ---------------------------------------------------------------------------

  defp write_sink(args, outcome, walkback_used, opts) do
    now = Keyword.get(opts, :now, &DateTime.utc_now/0)

    line =
      %{
        verdict: outcome.verdict,
        transcript_path: args.transcript_path,
        walkback_used: walkback_used,
        timestamp: now.() |> DateTime.to_iso8601()
      }
      |> maybe_put(:component, args.component)
      |> maybe_put(:score, outcome.score)
      |> Jason.encode!()

    case File.open(args.sink_path, [:append, :utf8]) do
      {:ok, io} ->
        IO.puts(io, line)
        File.close(io)

      {:error, reason} ->
        {:error, {:sink_open, args.sink_path, reason}}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
