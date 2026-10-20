defmodule ToborGrade.CLI do
  @moduledoc """
  escript entry point for `tobor-grade` (`mix escript.build`).

  Boots the `:genai` application (Finch HTTP client and friends), runs
  `ToborGrade.run/1`, and exits: 0 graded · 1 grading failure · 2 usage ·
  3 recursion guard (`TOBOR_GRADING=1`).
  """

  def main(argv) do
    case Application.ensure_all_started(:genai) do
      {:ok, _} ->
        case ToborGrade.run(argv) do
          {:ok, summary} ->
            IO.puts("verdict: #{summary.verdict} (walkback_used: #{summary.walkback_used})")
            maybe_score(summary)
            IO.puts("sink: appended")
            System.halt(0)

          {:error, :grading_recursion_guard} ->
            IO.puts(:stderr, "tobor-grade: TOBOR_GRADING=1 set — refusing to grade recursively")
            System.halt(3)

          {:error, reason} ->
            IO.puts(:stderr, "tobor-grade: #{inspect(reason)}")
            System.halt((usage?(reason) && 2) || 1)
        end

      {:error, reason} ->
        IO.puts(:stderr, "tobor-grade: cannot start :genai application — #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp maybe_score(%{score: score}) when not is_nil(score),
    do: IO.puts("score: #{score}")

  defp maybe_score(_), do: :ok

  defp usage?({:missing_argument, _}), do: true
  defp usage?({:unknown_arguments, _}), do: true
  defp usage?({:unexpected_arguments, _}), do: true
  defp usage?({:invalid_sink, _}), do: true
  defp usage?({:invalid_walkback, _}), do: true
  defp usage?({:invalid_argument, _}), do: true
  defp usage?(_), do: false
end
