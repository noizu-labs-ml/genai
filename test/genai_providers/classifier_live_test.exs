defmodule GenAI.ClassifierProvidersLiveTest do
  use ExUnit.Case, async: false
  @moduletag :live
  alias GenAI.Classifier.{Question, Request, Result}
  alias GenAI.Pipeline
  alias GenAI.Pipeline.Snapshot
  alias GenAI.Provider.{Jev, Qwen}

  defp required(name) do
    case System.get_env(name) do
      value when is_binary(value) and value != "" -> value
      _ -> flunk("Unmet live prerequisite: #{name}")
    end
  end

  defp classifier(:jev), do: [provider: Jev, api_key: required("JEV_API_KEY")]

  defp classifier(:alibaba) do
    config = Application.get_env(:genai, :qwen, [])

    [
      provider: Qwen,
      distribution_diagnostics: fn stats ->
        Enum.each(stats, fn stat ->
          if stat.failed do
            IO.puts(
              "DECISION distribution: type=#{stat.question_type} expected=#{stat.expected_count} received=#{stat.received_count} keys_match=#{stat.key_match} values_valid=#{stat.values_valid} sum=#{stat.sum} decimal_places_min=#{stat.decimal_places_min} decimal_places_max=#{stat.decimal_places_max} raw_score=#{stat.raw_score} raw_score_decimal_places=#{stat.raw_score_decimal_places} weighted_raw_index=#{stat.weighted_raw_index} weighted_normalized_index=#{stat.weighted_normalized_index} score_delta_raw=#{stat.score_delta_raw} score_delta_normalized=#{stat.score_delta_normalized} tolerance=#{stat.tolerance}"
            )
          end
        end)
      end,
      api_key:
        required_value(
          [
            config[:decision_api_key],
            config[:api_key],
            System.get_env("QWEN_API_KEY"),
            System.get_env("DASHSCOPE_API_KEY")
          ],
          "decision API key"
        ),
      decision_base_url:
        required_value(
          [config[:decision_base_url], System.get_env("QWEN_DECISION_BASE_URL")],
          "decision base URL"
        )
    ]
  end

  defp required_value(candidates, label) do
    case Enum.find(candidates, &(is_binary(&1) && &1 != "" && &1 != "test-key")) do
      nil -> flunk("Unmet live prerequisite: " <> label)
      value -> value
    end
  end

  defp configured_key do
    config = Application.get_env(:genai, :qwen, [])

    required_value(
      [config[:api_key], System.get_env("QWEN_API_KEY"), System.get_env("DASHSCOPE_API_KEY")],
      "Qwen API key"
    )
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
      when tag in [:http_error, :system_one_http, :dashscope_http_error, :dashscope_stream_error] and
             is_integer(status) ->
        flunk("#{stage}: HTTP #{status}")

      {:error, reason} when is_atom(reason) ->
        flunk(stage <> ": codec reason=" <> Atom.to_string(reason))

      {:error, {:invalid_system_one_answer, _question_id, reason}}
      when reason in [
             :unknown_choice,
             :choice_probability,
             :noul_probability,
             :score_or_legend,
             :type
           ] ->
        flunk(stage <> ": codec reason=" <> Atom.to_string(reason))

      {:error, reason} when is_tuple(reason) and is_atom(elem(reason, 0)) ->
        flunk(stage <> ": error tag=" <> Atom.to_string(elem(reason, 0)))

      _ ->
        flunk(stage <> ": unsupported failure shape (redacted)")
    end
  end

  defp classifier(:local) do
    loaded =
      safe_ok(
        Jev.Local.load(required("GENAI_JEV_MODEL_PATH"), required("GENAI_JEV_HEAD_PATH"),
          model_id: "akhilaaa3/Jev-Omni",
          model_options: [n_gpu_layers: 99],
          context_options: [n_ctx: 2048, n_batch: 256, n_ubatch: 256]
        ),
        "local classifier load"
      )

    [provider: Jev.Local, model: Jev.Local.model(), classifier: loaded]
  end

  defp chat_pipeline do
    key = configured_key()

    thread =
      GenAI.chat(:session)
      |> GenAI.with_model(
        Qwen.Models.model(System.get_env("GENAI_LIVE_CHAT_MODEL") || "qwen-plus")
      )
      |> GenAI.with_setting(:api_key, key)
      |> GenAI.with_setting(:enable_thinking, false)
      |> GenAI.with_setting(:max_tokens, 256)
      |> GenAI.with_message(
        GenAI.Message.user("Synthetic ticket: I was charged twice and request a refund.")
      )

    pipeline = safe_ok(Pipeline.new(thread), "pipeline setup")
    pipeline
  end

  defp messages(pipeline) do
    thread =
      safe_ok(
        Snapshot.materialize(pipeline.thread, pipeline.context, pipeline.options),
        "transcript projection"
      )

    Snapshot.messages(thread)
  end

  defp next_once(pipeline) do
    before = messages(pipeline)
    observer = self()

    runner = fn thread, context, opts ->
      send(observer, :continuing_turn)
      GenAI.run(thread, context, opts)
    end

    continued =
      safe_ok(Pipeline.next_turn(pipeline, run: runner, timeout: 120_000), "continuation")

    assert_receive :continuing_turn
    refute_receive :continuing_turn
    after_messages = messages(continued)
    assert Enum.take(after_messages, length(before)) == before
    assert length(after_messages) == length(before) + 1
    continued
  end

  for provider <- [:jev, :alibaba, :local] do
    @tag provider: provider
    @tag :"#{provider}_direct"
    test "#{provider} performs real synthetic choice, boolean and score inference" do
      provider = unquote(provider)
      levels = if provider == :alibaba, do: 10, else: 3

      rubric =
        Enum.map(0..(levels - 1), &%{id: "level-#{&1}", label: "Severity level #{&1}", score: &1})

      request = %Request{
        input: "Synthetic billing ticket: duplicate charge; refund requested.",
        questions: [
          %Question{
            id: "route",
            instructions: "Route the ticket",
            choices: ["billing", "technical"]
          },
          %Question{
            id: "refund",
            type: :boolean,
            instructions: "Does the ticket request a refund?"
          },
          %Question{
            id: "severity",
            type: :score,
            instructions: "Rate severity low to high",
            rubric: rubric
          }
        ]
      }

      result = safe_ok(GenAI.classify(request, classifier(provider)), "direct classification")

      {route, boolean, score} =
        case result do
          %Result{answers: [route, boolean, score]} -> {route, boolean, score}
          _ -> flunk("direct classification: invalid normalized answer shape")
        end

      assert route.choice_id in ["billing", "technical"]
      assert is_boolean(boolean.value)
      assert length(score.distribution) == levels
      assert is_number(score.expected_score)
      if provider != :local, do: assert(is_number(score.metadata.wire_expected_index))
    end

    @tag provider: provider
    @tag :"#{provider}_inline"
    test "#{provider} supports dynamic inference criteria and a correlated inline result before continuing" do
      pipeline = chat_pipeline()
      original = messages(pipeline)

      prompt =
        "Extract the synthetic ticket as payload and criteria as one choice question: id route, type choice, choices billing and technical, instructions route the ticket. Return the required JSON envelope."

      extracted =
        safe_ok(
          Pipeline.extract(pipeline, {:inference, prompt},
            kind: :both,
            tool: false,
            timeout: 120_000
          ),
          "dynamic extraction"
        )

      assert messages(extracted) == original

      classified =
        safe_ok(
          Pipeline.classify(extracted, classifier(unquote(provider))),
          "inline classification"
        )

      appended = safe_ok(Pipeline.append_result(classified), "inline result injection")
      transcript = messages(appended)
      assert %GenAI.Message.ToolUsage{tool_calls: [call]} = Enum.at(transcript, -2)
      assert %GenAI.Message.ToolResponse{tool_call_id: response_id} = List.last(transcript)
      assert call.id == response_id
      next_once(appended)
    end

    @tag provider: provider
    @tag :"#{provider}_fork"
    test "#{provider} selects a fork and continues its preserved history exactly once" do
      pipeline = chat_pipeline()

      fork =
        Pipeline.fork(pipeline, [
          {"helpful",
           fn p ->
             Pipeline.transform(
               p,
               fn thread, _options ->
                 GenAI.with_message(
                   thread,
                   GenAI.Message.assistant(
                     "I will explain how to request the duplicate-charge refund."
                   )
                 )
               end
             )
           end},
          {"unhelpful",
           fn p ->
             Pipeline.transform(
               p,
               fn thread, _options ->
                 GenAI.with_message(
                   thread,
                   GenAI.Message.assistant("This billing issue is irrelevant.")
                 )
               end
             )
           end}
        ])

      branches =
        case fork do
          %GenAI.Thread.Fork{branches: branches} -> branches
          _ -> flunk("fork setup: invalid branch shape")
        end

      opts =
        Keyword.put(
          classifier(unquote(provider)),
          :instructions,
          "Choose the branch that helps the customer resolve the refund."
        )

      selected =
        safe_ok(
          Pipeline.join(fork, mode: :select, selector: {:classifier, opts}),
          "fork selection"
        )

      unless Enum.any?(branches, &(&1.pipeline == selected)),
        do: flunk("fork selection: selected history was not preserved")

      next_once(selected)
    end
  end
end
