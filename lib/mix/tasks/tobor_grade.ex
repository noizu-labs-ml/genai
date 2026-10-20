defmodule Mix.Tasks.ToborGrade do
  @shortdoc "Grade a transcript with the Jev/Alibaba classifiers (tobor-grade)."

  @moduledoc """
  Grade one agent transcript and append one JSONL line to the sink.

      mix tobor_grade --transcript <path> [--walkback N] --sink jsonl:<path> [--score] [--component <tag>]

  - default lane: hosted Jev (`jev-latest`) `:choice` verdict —
    continuation | topic-switch | new-task | more-context-needed.
  - `--score`: Alibaba `decision-model-preview` 0-100 `:score` grading
    (`:alibaba_rounded_hundredths` policy applies inside the SystemOne adapter).
  - `--walkback N` (cap #{ToborGrade.walkback_cap()}): on `more-context-needed`,
    walk the transcript back one user turn and re-grade, up to N times.
  - `--sink jsonl:<path>` appends
    `{component?, verdict, score?, transcript_path, walkback_used, timestamp}`.
  - Refuses to run when `TOBOR_GRADING=1` (recursion guard).

  Exit codes: 0 graded · 1 grading failure · 2 usage · 3 recursion guard.
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    case ToborGrade.run(argv) do
      {:ok, summary} ->
        Mix.shell().info(verdict_line(summary))

      {:error, :grading_recursion_guard} ->
        Mix.shell().error("tobor-grade: TOBOR_GRADING=1 set — refusing to grade recursively")

        exit({:shutdown, 3})

      {:error, reason} ->
        Mix.shell().error("tobor-grade: #{format_error(reason)}")

        exit({:shutdown, exit_code(reason)})
    end
  end

  defp verdict_line(summary) do
    base = "verdict: #{summary.verdict} (walkback_used: #{summary.walkback_used})"
    base = if summary[:score], do: base <> " score: #{summary.score}", else: base
    base <> " sink: appended"
  end

  defp exit_code({:missing_argument, _}), do: 2
  defp exit_code({:unknown_arguments, _}), do: 2
  defp exit_code({:unexpected_arguments, _}), do: 2
  defp exit_code({:invalid_sink, _}), do: 2
  defp exit_code({:invalid_walkback, _}), do: 2
  defp exit_code({:invalid_argument, _}), do: 2
  defp exit_code(_), do: 1

  defp format_error({:missing_argument, flag}), do: "missing --#{flag}"
  defp format_error({:unknown_arguments, list}), do: "unknown arguments: #{inspect(list)}"
  defp format_error({:unexpected_arguments, list}), do: "unexpected arguments: #{inspect(list)}"
  defp format_error({:invalid_sink, reason}), do: "invalid --sink: #{reason}"
  defp format_error({:invalid_walkback, {:cap, cap}}), do: "--walkback cap is #{cap}"
  defp format_error({:invalid_walkback, value}), do: "invalid --walkback: #{inspect(value)}"
  defp format_error({:invalid_argument, flag}), do: "invalid --#{flag}"

  defp format_error({:transcript_read, path, reason}),
    do: "cannot read transcript #{path}: #{inspect(reason)}"

  defp format_error({:invalid_transcript_line, n}), do: "invalid transcript JSON on line #{n}"
  defp format_error(:invalid_transcript), do: "invalid transcript"

  defp format_error({:missing_answer, id}),
    do: "classifier result has no answer for question #{inspect(id)}"

  defp format_error({:sink_open, path, reason}),
    do: "cannot open sink #{path}: #{inspect(reason)}"

  defp format_error(reason), do: inspect(reason)
end
