defmodule GenAI.Provider.SystemOne.Rounded do
  @moduledoc false
  @epsilon 1.0e-10
  @half_step 0.005

  # An inferred Alibaba wire policy, not recovery of its hidden distribution.
  def normalize(values, type, native_score) when is_list(values) and type in [:choice, :score] do
    count = length(values)

    with true <- count in 2..10 and Enum.all?(values, &GenAI.Classifier.Validation.probability?/1),
         sum = Enum.sum(values),
         true <- sum > 0,
         true <- Enum.all?(values, &grid?/1),
         true <- abs(sum - 1) <= min(count * @half_step, 0.01) + @epsilon,
         bounds = Enum.map(values, &{max(0.0, &1 - @half_step), min(1.0, &1 + @half_step)}),
         true <- Enum.all?(bounds, fn {lower, upper} -> lower <= upper end),
         lower_sum = Enum.reduce(bounds, 0.0, fn {lower, _}, total -> total + lower end),
         upper_sum = Enum.reduce(bounds, 0.0, fn {_, upper}, total -> total + upper end),
         true <- lower_sum <= 1 + @epsilon and upper_sum >= 1 - @epsilon,
         minimum = attainable_mean(bounds, :ascending),
         maximum = attainable_mean(bounds, :descending),
         true <- score_valid?(type, native_score, minimum, maximum, count) do
      canonical = Enum.map(values, &(&1 / sum))

      {:ok, canonical,
       %{
         distribution_policy: :alibaba_rounded_hundredths,
         policy_provenance: :inferred_from_observed_wire_precision,
         canonical_distribution_source: :unit_normalized_displayed_estimate,
         wire_distribution_sum: sum,
         wire_weighted_index: weighted(values),
         canonical_weighted_index: weighted(canonical),
         attainable_index_min: minimum,
         attainable_index_max: maximum
       }}
    else
      false -> {:error, :invalid_system_one_rounded_distribution_or_score}
    end
  end

  def normalize(_, _, _), do: {:error, :invalid_system_one_rounded_distribution_or_score}

  defp grid?(value), do: abs(value * 100 - round(value * 100)) <= @epsilon
  defp score_valid?(:choice, _, _, _, _), do: true

  defp score_valid?(:score, score, minimum, maximum, count) do
    is_number(score) and score == score and score >= 0 and score <= count - 1 and
      grid?(score) and score >= minimum - @half_step - @epsilon and
      score <= maximum + @half_step + @epsilon
  end

  defp attainable_mean(bounds, direction) do
    base = Enum.reduce(bounds, 0.0, fn {lower, _}, total -> total + lower end)
    indexed = Enum.with_index(bounds)
    indexed = if direction == :descending, do: Enum.reverse(indexed), else: indexed

    {_, mean} =
      Enum.reduce(indexed, {max(0.0, 1 - base), 0.0}, fn {{lower, upper}, index}, {mass, mean} ->
        extra = min(mass, upper - lower)
        {max(0.0, mass - extra), mean + (lower + extra) * index}
      end)

    mean
  end

  defp weighted(values),
    do: Enum.with_index(values) |> Enum.reduce(0.0, fn {p, i}, total -> total + p * i end)
end
