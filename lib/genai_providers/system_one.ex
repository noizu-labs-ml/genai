defmodule GenAI.Provider.SystemOne do
  @moduledoc """
  Shared TypeSafe System One wire adapter. All external keys stay strings.
  Score indices are validated before remapping to the caller's numeric rubric.
  Noul probabilities use an explicit boolean threshold; no confidence is invented.
  """
  alias GenAI.Classifier.{Question, Request, Result, Validation}
  alias GenAI.Classifier.Result.Answer

  @doc "Execute a classifier request through a configured System One endpoint."
  def classify(provider, request, settings, options \\ []) do
    started = System.monotonic_time(:microsecond)

    with {:ok, request} <- Request.normalize(request),
         {:ok, body} <- encode(request, settings[:model]),
         {:ok, url} <- endpoint(settings[:base_url], :systemone),
         {:ok, json} <- http(:post, url, settings[:api_key], body, options),
         options = classifier_policy(options, provider, body.model),
         {:ok, result} <- decode(json, request, provider, options) do
      {:ok, %{result | duration: System.monotonic_time(:microsecond) - started}}
    end
  end

  defp classifier_policy(options, GenAI.Provider.Qwen, "decision-model-preview"),
    do: Keyword.put_new(options, :distribution_policy, :alibaba_rounded_hundredths)

  defp classifier_policy(options, _, _), do: Keyword.put(options, :distribution_policy, :strict)

  @doc "Build an endpoint without duplicating an existing v1 or endpoint segment."
  def endpoint(base, operation) when is_binary(base) and operation in [:systemone, :models] do
    uri = URI.parse(base)

    if uri.scheme in ["https", "http"] and is_binary(uri.host) and is_nil(uri.userinfo) and
         is_nil(uri.query) and is_nil(uri.fragment) do
      path =
        String.trim_trailing(uri.path || "", "/") |> String.replace(~r{/(systemone|models)$}, "")

      {:ok, URI.to_string(%{uri | path: path <> "/" <> Atom.to_string(operation)})}
    else
      {:error, :invalid_system_one_endpoint}
    end
  end

  def endpoint(_, _), do: {:error, :missing_system_one_endpoint}

  @doc "Fetch a model catalog using the same redacted HTTP boundary."
  def models(settings, options \\ []) do
    with {:ok, url} <- endpoint(settings[:base_url], :models) do
      http(:get, url, settings[:api_key], nil, options)
    end
  end

  @doc "Encode typed questions using stable question/option IDs."
  def encode(%Request{} = request, default_model \\ nil) do
    model =
      case request.model do
        %GenAI.Model{model: name} -> name
        nil -> default_model
      end

    with true <- Validation.string?(model),
         true <- request.modality == :text,
         true <- is_binary(request.input) or is_map(request.input) or is_list(request.input),
         {:ok, questions} <- Validation.collect(request.questions, &wire_question/1) do
      {:ok, %{model: model, state: request.input, questions: Map.new(questions)}}
    else
      false -> {:error, :invalid_system_one_model_or_state}
      {:error, _} = error -> error
    end
  end

  defp wire_question(%Question{} = question) do
    type =
      case question.type do
        :boolean -> "noul"
        :choice -> "choice"
        :score -> "score"
      end

    entries = Question.entries(question)

    cond do
      question.type == :choice and length(entries) > 255 ->
        {:error, {:classifier_limit, :max_choices}}

      question.type == :score and length(entries) > 10 ->
        {:error, {:classifier_limit, :max_score_levels}}

      true ->
        value = %{
          type: type,
          instructions: question.instructions || default_instruction(question.type)
        }

        value =
          case question.type do
            :choice -> Map.put(value, :criteria, Map.new(entries, &{&1.id, &1.label}))
            :score -> Map.put(value, :criteria, Enum.map(entries, & &1.label))
            :boolean -> value
          end

        {:ok, {question.id, value}}
    end
  end

  defp default_instruction(:boolean), do: "Is the statement true?"
  defp default_instruction(:choice), do: "Which option best describes the state?"
  defp default_instruction(:score), do: "Which rubric level best describes the state?"

  @doc "Decode and validate ordered distributions and native decision semantics."
  def decode(json, request, provider, options \\ [])

  def decode(json, %Request{} = request, provider, options) when is_map(json) do
    answers = json["answers"]
    threshold = Keyword.get(options, :boolean_threshold, 0.5)
    model_name = json["model"] || (request.model && request.model.model)

    policy =
      if provider == GenAI.Provider.Qwen and model_name == "decision-model-preview" and
           (is_nil(request.model) or request.model.model == "decision-model-preview"),
         do: Keyword.get(options, :distribution_policy, :strict),
         else: :strict

    expected_ids = Enum.map(request.questions, & &1.id)

    with true <- is_map(answers) and Enum.sort(Map.keys(answers)) == Enum.sort(expected_ids),
         true <- Validation.probability?(threshold),
         {:ok, normalized} <-
           Validation.collect(request.questions, fn question ->
             decode_answer(answers[question.id], question, {threshold, policy})
           end),
         true <- Validation.string?(model_name),
         result = %Result{
           answers: normalized,
           model: %GenAI.Model{model: model_name, provider: provider},
           provider: provider,
           usage: safe_usage(json["usage"]),
           metadata: response_metadata(json)
         },
         {:ok, result} <- Result.normalize(result, request) do
      {:ok, result}
    else
      false ->
        {:error, :invalid_system_one_response}

      {:error, :invalid_system_one_distribution} = error ->
        emit_distribution_diagnostics(json, request, options)
        error

      {:error, _} = error ->
        error
    end
  end

  def decode(_, _, _, _), do: {:error, :invalid_system_one_response}

  # Explicit diagnostic seam. Only bounded, trusted shape/numeric fields leave
  # this boundary; request IDs, option labels, payloads, credentials and raw JSON
  # are never supplied to the callback. Classification validation is unchanged.
  defp emit_distribution_diagnostics(json, request, options) do
    if is_function(options[:distribution_diagnostics], 1) do
      stats =
        request.questions
        |> Enum.filter(&(&1.type in [:choice, :score]))
        |> Enum.map(fn question ->
          entries = Question.entries(question)

          keys =
            if question.type == :choice,
              do: Enum.map(entries, & &1.id),
              else: Enum.map(0..(length(entries) - 1), &Integer.to_string/1)

          wire = get_in(json, ["answers", question.id, "probabilities"])
          values = if is_map(wire), do: Enum.map(keys, &Map.get(wire, &1)), else: []
          valid = length(values) == length(keys) and Enum.all?(values, &Validation.probability?/1)
          sum = if valid, do: Enum.sum(values), else: nil
          matched = is_map(wire) and Enum.sort(Map.keys(wire)) == Enum.sort(keys)
          precision = if valid, do: Enum.map(values, &decimal_places/1), else: []
          candidate_score = get_in(json, ["answers", question.id, "score"])

          raw_score =
            if question.type == :score and Validation.number?(candidate_score) and
                 candidate_score >= 0 and candidate_score <= length(keys) - 1,
               do: candidate_score,
               else: nil

          raw_index =
            if question.type == :score and valid do
              Enum.with_index(values)
              |> Enum.reduce(0.0, fn {value, index}, total -> total + value * index end)
            end

          normalized_index = if is_number(raw_index) and sum > 0, do: raw_index / sum

          %{
            question_type: question.type,
            expected_count: length(keys),
            received_count: if(is_map(wire), do: map_size(wire), else: 0),
            key_match: matched,
            values_valid: valid,
            sum: sum,
            # Precision describes decoded numbers' shortest decimal forms, not
            # a promise about the provider's original JSON serialization.
            decimal_places_min: if(precision != [], do: Enum.min(precision)),
            decimal_places_max: if(precision != [], do: Enum.max(precision)),
            raw_score: raw_score,
            raw_score_decimal_places: if(is_number(raw_score), do: decimal_places(raw_score)),
            weighted_raw_index: raw_index,
            weighted_normalized_index: normalized_index,
            score_delta_raw:
              if(is_number(raw_score) and is_number(raw_index), do: raw_score - raw_index),
            score_delta_normalized:
              if(is_number(raw_score) and is_number(normalized_index),
                do: raw_score - normalized_index
              ),
            tolerance: 1.0e-6,
            failed: not (matched and valid and abs(sum - 1) <= 1.0e-6)
          }
        end)

      options[:distribution_diagnostics].(stats)
    end

    :ok
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end

  defp decimal_places(value) when is_integer(value), do: 0

  defp decimal_places(value) when is_float(value) do
    [mantissa | exponent] = String.split(:erlang.float_to_binary(value, [:short]), "e")
    decimal = List.last(String.split(mantissa, "."))

    fractional_digits =
      if String.contains?(mantissa, "."),
        do: String.length(String.trim_trailing(decimal, "0")),
        else: 0

    exponent = if exponent == [], do: 0, else: String.to_integer(hd(exponent))
    max(0, fractional_digits - exponent)
  end

  defp decode_answer(
         %{"type" => "choice"} = wire,
         %Question{type: :choice} = question,
         {_, policy}
       ) do
    entries = Question.entries(question)
    ids = Enum.map(entries, & &1.id)

    with {:ok, probabilities, provenance} <-
           distribution(wire["probabilities"], ids, policy, :choice, nil),
         index when is_integer(index) <- Enum.find_index(ids, &(&1 == wire["choice"])),
         true <- Enum.at(probabilities, index) + 1.0e-6 >= Enum.max(probabilities),
         :ok <- confidence(wire["confidence"]) do
      {:ok,
       %Answer{
         question_id: question.id,
         type: :choice,
         index: index,
         choice_id: Enum.at(ids, index),
         value: Enum.at(ids, index),
         distribution: probabilities,
         selected_probability: Enum.at(probabilities, index),
         provider_confidence: wire["confidence"],
         confidence_metadata: %{meaning: :provider_distribution_confidence},
         metadata:
           Map.merge(
             %{wire_type: "choice", selected_probability_source: :distribution},
             provenance
           )
       }}
    else
      nil -> {:error, {:invalid_system_one_answer, question.id, :unknown_choice}}
      false -> {:error, {:invalid_system_one_answer, question.id, :choice_probability}}
      {:error, _} = error -> error
    end
  end

  defp decode_answer(
         %{"type" => "noul", "noul" => probability},
         %Question{type: :boolean} = question,
         {threshold, _}
       ) do
    if Validation.probability?(probability) do
      value = probability > threshold

      {:ok,
       %Answer{
         question_id: question.id,
         type: :boolean,
         value: value,
         distribution: [1 - probability, probability],
         selected_probability: if(value, do: probability, else: 1 - probability),
         metadata: %{
           wire_type: "noul",
           positive_probability: probability,
           boolean_threshold: threshold,
           selection_policy: :strict_greater_than,
           distribution_source: :binary_probability
         }
       }}
    else
      {:error, {:invalid_system_one_answer, question.id, :noul_probability}}
    end
  end

  defp decode_answer(%{"type" => "score"} = wire, %Question{type: :score} = question, {_, policy}) do
    entries = Question.entries(question)
    indices = Enum.map(0..(length(entries) - 1), &Integer.to_string/1)

    with {:ok, probabilities, provenance} <-
           distribution(wire["probabilities"], indices, policy, :score, wire["score"]),
         true <-
           is_map(wire["legend"]) and Enum.sort(Map.keys(wire["legend"])) == Enum.sort(indices),
         true <-
           Enum.zip(indices, entries)
           |> Enum.all?(fn {index, entry} -> wire["legend"][index] == entry.label end),
         true <- Validation.number?(wire["score"]),
         native_mean =
           Enum.with_index(probabilities)
           |> Enum.reduce(0.0, fn {p, i}, total -> total + p * i end),
         true <-
           policy == :alibaba_rounded_hundredths or
             abs(native_mean - wire["score"]) <= 1.0e-6 * max(1, abs(native_mean)),
         :ok <- confidence(wire["confidence"]) do
      mean =
        Enum.zip(entries, probabilities)
        |> Enum.reduce(0.0, fn {entry, p}, total -> total + entry.score * p end)

      {:ok,
       %Answer{
         question_id: question.id,
         type: :score,
         expected_score: mean,
         distribution: probabilities,
         provider_confidence: wire["confidence"],
         confidence_metadata: %{meaning: :provider_distribution_confidence},
         metadata:
           Map.merge(
             %{
               wire_type: "score",
               wire_expected_index: wire["score"],
               legend: wire["legend"],
               score_mapping: :caller_numeric_rubric
             },
             provenance
           )
       }}
    else
      false -> {:error, {:invalid_system_one_answer, question.id, :score_or_legend}}
      {:error, _} = error -> error
    end
  end

  defp decode_answer(_, question, _),
    do: {:error, {:invalid_system_one_answer, question.id, :type}}

  defp distribution(map, keys, policy, type, native_score) when is_map(map) do
    values = Enum.map(keys, &Map.get(map, &1))

    if Enum.sort(Map.keys(map)) == Enum.sort(keys) and
         Enum.all?(values, &Validation.probability?/1) do
      if policy == :alibaba_rounded_hundredths do
        if abs(Enum.sum(values) - 1) <= 1.0e-6 and
             (type == :choice or strict_score?(values, native_score)) do
          {:ok, values, %{}}
        else
          GenAI.Provider.SystemOne.Rounded.normalize(values, type, native_score)
        end
      else
        if abs(Enum.sum(values) - 1) <= 1.0e-6,
          do: {:ok, values, %{}},
          else: {:error, :invalid_system_one_distribution}
      end
    else
      {:error, :invalid_system_one_distribution}
    end
  end

  defp distribution(_, _, _, _, _), do: {:error, :invalid_system_one_distribution}

  defp strict_score?(values, native_score) do
    mean = Enum.with_index(values) |> Enum.reduce(0.0, fn {p, i}, total -> total + p * i end)
    Validation.number?(native_score) and abs(mean - native_score) <= 1.0e-6 * max(1, abs(mean))
  end

  defp confidence(nil), do: :ok

  defp confidence(value),
    do:
      if(Validation.probability?(value), do: :ok, else: {:error, :invalid_system_one_confidence})

  defp response_metadata(json) do
    metadata = %{duration_unit: :microsecond}

    metadata =
      if is_binary(json["request_id"]),
        do: Map.put(metadata, :request_id, json["request_id"]),
        else: metadata

    if Validation.number?(json["latency_ms"]),
      do: Map.put(metadata, :server_latency_ms, json["latency_ms"]),
      else: metadata
  end

  defp safe_usage(usage) when is_map(usage) do
    usage
    |> Map.take(["input_tokens", "output_tokens", "total_tokens"])
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value >= 0 end)
    |> Map.new()
  end

  defp safe_usage(_), do: nil

  defp http(method, url, key, body, options) do
    if Validation.string?(key) do
      encoded = if is_nil(body), do: {:ok, nil}, else: Jason.encode(body)

      with {:ok, encoded} <- encoded,
           {:ok, response} <-
             Finch.request(
               Finch.build(
                 method,
                 url,
                 [{"authorization", "Bearer " <> key}, {"content-type", "application/json"}],
                 encoded
               ),
               Keyword.get(options, :finch, GenAI.Finch),
               receive_timeout: Keyword.get(options, :receive_timeout, 60_000)
             ) do
        case response do
          %Finch.Response{status: 200, body: body} ->
            case Jason.decode(body) do
              {:ok, json} when is_map(json) -> {:ok, json}
              _ -> {:error, :invalid_system_one_json}
            end

          %Finch.Response{status: status} ->
            {:error, {:system_one_http, status}}
        end
      else
        _ -> {:error, :system_one_transport_or_encoding_error}
      end
    else
      {:error, :missing_system_one_api_key}
    end
  rescue
    _ -> {:error, :system_one_transport_or_encoding_error}
  end
end
