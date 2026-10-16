defmodule GenAI.ClassifierProvidersTest do
  use ExUnit.Case, async: false

  setup do
    originals =
      for provider <- [:qwen, :jev], do: {provider, Application.get_env(:genai, provider)}

    Application.put_env(:genai, :qwen,
      api_key: "fixture-key",
      token_api_key: "fixture-token-key",
      base_url: "https://fixture.example/compatible-mode/v1",
      native_base_url: "https://fixture.example/api/v1",
      decision_base_url: "https://fixture.example/compatible-mode/v1",
      token_plan: false
    )

    Application.put_env(:genai, :jev,
      api_key: "fixture-key",
      base_url: "https://fixture.example/v1"
    )

    on_exit(fn ->
      Enum.each(originals, fn {provider, config} ->
        if is_nil(config),
          do: Application.delete_env(:genai, provider),
          else: Application.put_env(:genai, provider, config)
      end)
    end)

    :ok
  end

  alias GenAI.Classifier.{Question, Request, Result}
  alias GenAI.Provider.{Jev, Qwen, SystemOne}

  setup do
    Mimic.set_mimic_global()
    :ok
  end

  defp request do
    %Request{
      input: %{ticket: "Synthetic duplicate payment refund request"},
      questions: [
        %Question{
          id: "route",
          choices: [%{id: "billing", label: "Payments"}, %{id: "technical", label: "Software"}],
          instructions: "Route the ticket"
        },
        %Question{id: "refund", type: :boolean, instructions: "Does this ask for a refund?"},
        %Question{
          id: "severity",
          type: :score,
          instructions: "Grade severity",
          rubric: [
            %{id: "low", label: "Low", score: -10},
            %{id: "medium", label: "Medium", score: 0},
            %{id: "high", label: "High", score: 100}
          ]
        }
      ]
    }
  end

  defp response do
    %{
      "model" => "jev-pinned",
      "request_id" => "fixture-id",
      "usage" => %{"input_tokens" => 23, "api_key" => "fixture-secret"},
      "latency_ms" => 2.5,
      "answers" => %{
        "route" => %{
          "type" => "choice",
          "choice" => "billing",
          "probabilities" => %{"technical" => 0.2, "billing" => 0.8},
          "confidence" => 0.6
        },
        "refund" => %{"type" => "noul", "noul" => 0.9},
        "severity" => %{
          "type" => "score",
          "score" => 1.6,
          "probabilities" => %{"2" => 0.7, "0" => 0.1, "1" => 0.2},
          "legend" => %{"0" => "Low", "1" => "Medium", "2" => "High"},
          "confidence" => 0.7
        }
      }
    }
  end

  defp reply(body, status \\ 200),
    do: %Finch.Response{status: status, body: Jason.encode!(body), headers: []}

  defp normalized do
    {:ok, request} = Request.normalize(request())
    request
  end

  test "encodes question IDs, choice descriptions and ordinal labels without changing order" do
    assert {:ok, body} = SystemOne.encode(normalized(), "jev-latest")
    assert body.model == "jev-latest"
    assert body.questions["refund"].type == "noul"

    assert body.questions["route"].criteria == %{
             "billing" => "Payments",
             "technical" => "Software"
           }

    assert body.questions["severity"].criteria == ["Low", "Medium", "High"]
  end

  test "normalizes choices, native noul probability and non-linear numeric rubric scores" do
    assert {:ok, %Result{answers: [choice, boolean, score]}} =
             SystemOne.decode(response(), normalized(), Jev)

    assert choice.index == 0
    assert choice.distribution == [0.8, 0.2]
    assert choice.selected_probability == 0.8
    assert choice.provider_confidence == 0.6
    assert boolean.value == true
    assert_in_delta hd(boolean.distribution), 0.1, 1.0e-12
    assert boolean.metadata.positive_probability == 0.9
    assert boolean.provider_confidence == nil
    assert_in_delta score.expected_score, 69.0, 1.0e-12
    assert score.metadata.wire_expected_index == 1.6
    assert score.grade == nil
    assert score.index == nil
  end

  test "retains only safe usage and response metadata" do
    assert {:ok, result} =
             SystemOne.decode(Map.put(response(), "api_key", "fixture-secret"), normalized(), Jev)

    assert result.usage == %{"input_tokens" => 23}
    assert result.metadata.request_id == "fixture-id"
    refute inspect(result) =~ "fixture-secret"
    refute inspect(result) =~ "authorization"
  end

  test "validates native index expectation before remapping to the caller's scale" do
    body = put_in(response(), ["answers", "severity", "score"], 69.0)

    assert {:error, {:invalid_system_one_answer, "severity", :score_or_legend}} =
             SystemOne.decode(body, normalized(), Jev)
  end

  test "validates option probabilities, selected maximum, confidence and legends" do
    for body <- [
          put_in(response(), ["answers", "route", "probabilities"], %{
            "billing" => 0.2,
            "technical" => 0.2
          }),
          put_in(response(), ["answers", "route", "choice"], "technical"),
          put_in(response(), ["answers", "route", "confidence"], 2),
          put_in(response(), ["answers", "severity", "legend", "0"], "Wrong rubric")
        ] do
      assert {:error, _} = SystemOne.decode(body, normalized(), Jev)
    end
  end

  test "rejects missing, additional or mismatched answers" do
    for body <- [
          Map.put(response(), "answers", %{}),
          put_in(response(), ["answers", "extra"], %{}),
          put_in(response(), ["answers", "refund", "type"], "choice")
        ] do
      assert {:error, _} = SystemOne.decode(body, normalized(), Jev)
    end
  end

  test "uses documented boolean threshold with deterministic false ties" do
    body = put_in(response(), ["answers", "refund", "noul"], 0.5)
    assert {:ok, %Result{answers: [_, answer, _]}} = SystemOne.decode(body, normalized(), Jev)
    assert answer.value == false

    assert {:ok, %Result{answers: [_, answer, _]}} =
             SystemOne.decode(response(), normalized(), Jev, boolean_threshold: 0.95)

    assert answer.value == false

    assert {:error, _} =
             SystemOne.decode(response(), normalized(), Jev, boolean_threshold: "secret-option")
  end

  test "builds supplied workspace endpoint exactly once without changing v1" do
    for base <- [
          "https://fixture.example/compatible-mode/v1",
          "https://fixture.example/compatible-mode/v1/",
          "https://fixture.example/compatible-mode/v1/systemone"
        ] do
      assert {:ok, "https://fixture.example/compatible-mode/v1/systemone"} =
               SystemOne.endpoint(base, :systemone)
    end

    assert {:error, _} =
             SystemOne.endpoint("https://user:password@fixture.example/v1", :systemone)

    assert {:error, _} = SystemOne.endpoint(nil, :systemone)
  end

  test "normalizes TypeSafe model discovery names and rejects incompatible catalog shapes" do
    assert {:ok, [%GenAI.Model{model: "jev-latest", provider: Jev}]} =
             Jev.Models.from_catalog(%{"models" => [%{"name" => "jev-latest"}]})

    assert {:error, :invalid_jev_model_catalog} =
             Jev.Models.from_catalog(%{"data" => [%{"id" => "jev-latest"}]})

    assert {:error, :invalid_jev_model_catalog} =
             Jev.Models.from_catalog(%{"models" => [%{"name" => nil}]})
  end

  @tag :requires_http_runtime
  test "routes hosted Jev through Core and parses models[] name catalogs" do
    Mimic.expect(Finch, :request, fn req, _, _ ->
      assert req.path == "/v1/models"

      {:ok,
       reply(%{
         models: [%{name: "jev-latest", description: "fixture", release_date: "2026-01-01"}]
       })}
    end)

    assert {:ok, [%GenAI.Model{model: "jev-latest", provider: Jev}]} =
             Jev.models(api_key: "fixture-key", base_url: "https://fixture.example/v1")

    Mimic.expect(Finch, :request, fn req, _, _ ->
      assert req.path == "/v1/systemone"
      assert Jason.decode!(req.body)["model"] == "jev-latest"
      {:ok, reply(response())}
    end)

    assert {:ok, %Result{provider: Jev, model: %GenAI.Model{model: "jev-pinned"}}} =
             GenAI.classify(request(),
               provider: Jev,
               api_key: "fixture-key",
               base_url: "https://fixture.example/v1"
             )
  end

  @tag :requires_http_runtime
  test "Qwen decision helper selects classifier endpoint and preserves ordinary chat configuration" do
    original = Qwen.base_url()

    Mimic.expect(Finch, :request, fn req, _, _ ->
      assert req.host == "workspace.example"
      assert req.path == "/compatible-mode/v1/systemone"
      assert Jason.decode!(req.body)["model"] == "decision-model-preview"
      {:ok, reply(%{response() | "model" => "decision-model-preview"})}
    end)

    assert {:ok, %Result{provider: Qwen}} =
             GenAI.classify(%{request() | model: Qwen.Models.decision_model_preview()},
               api_key: "fixture-key",
               decision_base_url: "https://workspace.example/compatible-mode/v1"
             )

    assert Qwen.base_url() == original
  end

  @tag :requires_http_runtime
  test "does not reveal secrets in HTTP or transport errors" do
    for status <- [401, 422, 429, 529] do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok, reply(%{error: "fixture-key"}, status)}
      end)

      assert {:error, {:system_one_http, ^status}} =
               Jev.classify(request(),
                 api_key: "fixture-key",
                 base_url: "https://fixture.example/v1"
               )
    end

    Mimic.expect(Finch, :request, fn _, _, _ -> {:error, "fixture-key"} end)

    assert {:error, :system_one_transport_or_encoding_error} =
             Jev.classify(request(),
               api_key: "fixture-key",
               base_url: "https://fixture.example/v1"
             )
  end

  test "classifier-only providers return explicit unsupported chat operations" do
    assert {:error, :classifier_only_provider} = Jev.run(nil, nil, [])
    assert {:error, :classifier_only_provider} = Jev.Local.stream(nil, nil, [])
  end

  test "limits ordinal scale without imposing the same ten-level cap on choices" do
    question = %Question{id: "many", choices: Enum.map(1..11, &Integer.to_string/1)}
    {:ok, request} = Request.normalize(%Request{input: "synthetic", questions: [question]})
    assert {:ok, _} = SystemOne.encode(request, "jev-latest")

    rubric =
      Enum.map(1..11, &%{id: Integer.to_string(&1), label: Integer.to_string(&1), score: &1})

    {:ok, request} =
      Request.normalize(%Request{
        input: "synthetic",
        questions: [%Question{id: "many", type: :score, rubric: rubric}]
      })

    assert {:error, {:classifier_limit, :max_score_levels}} =
             SystemOne.encode(request, "jev-latest")
  end

  test "distribution diagnostics expose bounded stats without relaxing malformed or precision validation" do
    for probabilities <- [
          %{"billing" => 0.7998046875, "technical" => 0.2000732421875},
          %{"billing" => %{api_key: "fixture-secret"}, "private" => "fixture-secret"}
        ] do
      body = put_in(response(), ["answers", "route", "probabilities"], probabilities)

      assert {:error, :invalid_system_one_distribution} =
               SystemOne.decode(body, normalized(), Jev,
                 distribution_diagnostics: fn stats -> send(self(), {:diagnostics, stats}) end
               )

      assert_received {:diagnostics, [choice, _score] = stats}
      assert choice.question_type == :choice
      assert choice.failed
      assert choice.expected_count == 2
      assert choice.received_count == 2
      assert choice.tolerance == 1.0e-6
      refute inspect(stats) =~ "fixture-secret"
      refute inspect(stats) =~ "api_key"
    end

    body =
      put_in(response(), ["answers", "route", "probabilities"], %{
        "billing" => 0.4,
        "technical" => 0.4
      })

    assert {:error, :invalid_system_one_distribution} =
             SystemOne.decode(body, normalized(), Jev,
               distribution_diagnostics: fn _ ->
                 raise "callback must not alter classification"
               end
             )
  end

  test "score diagnostics quantify decimal precision and raw versus normalized means safely" do
    for native_score <- [1.6, %{api_key: "fixture-secret"}, 999_999] do
      body =
        response()
        |> put_in(["answers", "severity", "probabilities"], %{
          "0" => 0.1,
          "1" => 0.2,
          "2" => 0.69
        })
        |> put_in(["answers", "severity", "score"], native_score)

      assert {:error, :invalid_system_one_distribution} =
               SystemOne.decode(body, normalized(), Jev,
                 distribution_diagnostics: fn stats -> send(self(), {:score_stats, stats}) end
               )

      assert_received {:score_stats, [choice, score] = stats}
      refute choice.failed
      assert score.failed
      assert score.key_match and score.values_valid
      assert_in_delta score.sum, 0.99, 1.0e-12
      assert score.decimal_places_min == 1
      assert score.decimal_places_max == 2
      assert_in_delta score.weighted_raw_index, 1.58, 1.0e-12
      assert_in_delta score.weighted_normalized_index, 1.58 / 0.99, 1.0e-12

      if native_score == 1.6 do
        assert score.raw_score == 1.6
        assert score.raw_score_decimal_places == 1
        assert_in_delta score.score_delta_raw, 0.02, 1.0e-12
        assert_in_delta score.score_delta_normalized, 1.6 - 1.58 / 0.99, 1.0e-12
      else
        assert is_nil(score.raw_score)
        assert is_nil(score.raw_score_decimal_places)
        assert is_nil(score.score_delta_raw)
        assert is_nil(score.score_delta_normalized)
      end

      refute inspect(stats) =~ "fixture-secret"
      refute inspect(stats) =~ "api_key"
      refute Enum.any?(Map.values(score), &(&1 == 999_999))
    end
  end

  defp rounded_decode(body, options \\ []) do
    SystemOne.decode(
      Map.put(body, "model", "decision-model-preview"),
      normalized(),
      Qwen,
      Keyword.put_new(options, :distribution_policy, :alibaba_rounded_hundredths)
    )
  end

  test "Alibaba rounded score remaps its canonical estimate onto a nonlinear caller rubric" do
    body =
      put_in(response(), ["answers", "severity", "probabilities"], %{
        "0" => 0.1,
        "1" => 0.2,
        "2" => 0.69
      })

    assert {:ok, result} = rounded_decode(body)
    score = Enum.at(result.answers, 2)
    assert_in_delta Enum.sum(score.distribution), 1.0, 1.0e-12
    assert_in_delta score.expected_score, 68 / 0.99, 1.0e-12
    assert is_nil(score.grade)
    assert score.provider_confidence == 0.7
    assert score.metadata.wire_expected_index == 1.6
    assert_in_delta score.metadata.wire_distribution_sum, 0.99, 1.0e-12
    assert score.metadata.policy_provenance == :inferred_from_observed_wire_precision
    assert score.metadata.canonical_distribution_source == :unit_normalized_displayed_estimate
    assert score.metadata.attainable_index_min - 0.005 - 1.0e-10 <= 1.6
    assert score.metadata.attainable_index_max + 0.005 + 1.0e-10 >= 1.6
  end

  test "rounded native score is checked against feasible bins even with displayed unit mass" do
    assert {:ok, _} = rounded_decode(put_in(response(), ["answers", "severity", "score"], 1.61))

    assert {:error, :invalid_system_one_rounded_distribution_or_score} =
             rounded_decode(put_in(response(), ["answers", "severity", "score"], 1.8))

    assert {:error, {:invalid_system_one_answer, "severity", :score_or_legend}} =
             rounded_decode(put_in(response(), ["answers", "severity", "score"], 1.61),
               distribution_policy: :strict
             )
  end

  test "rounded choices retain provider identity/confidence and use canonical selected probability" do
    body =
      put_in(response(), ["answers", "route", "probabilities"], %{
        "billing" => 0.79,
        "technical" => 0.2
      })

    assert {:ok, result} = rounded_decode(body)
    choice = hd(result.answers)
    assert choice.choice_id == "billing"
    assert choice.provider_confidence == 0.6
    assert_in_delta choice.selected_probability, 0.79 / 0.99, 1.0e-12

    assert {:error, :invalid_system_one_distribution} =
             rounded_decode(body, distribution_policy: :strict)

    assert {:error, :invalid_system_one_distribution} =
             SystemOne.decode(body, normalized(), Jev,
               distribution_policy: :alibaba_rounded_hundredths
             )
  end

  test "hundredth policy rejects malformed, high precision, gross mass and excess cardinality" do
    alias GenAI.Provider.SystemOne.Rounded

    for values <- [
          nil,
          ["private", 1],
          [-0.01, 0.51, 0.5],
          [1.01, 0],
          [0, 0],
          [0.495, 0.505],
          [0.48, 0.5],
          List.duplicate(0.09, 11)
        ] do
      assert {:error, :invalid_system_one_rounded_distribution_or_score} =
               Rounded.normalize(values, :choice, nil)
    end

    assert {:error, :invalid_system_one_rounded_distribution_or_score} =
             Rounded.normalize([0.5, 0.5], :unknown, nil)

    assert {:ok, _, _} = Rounded.normalize([0.49, 0.5], :choice, nil)
    assert {:ok, _, _} = Rounded.normalize([0, 1], :score, 1)

    assert {:error, :invalid_system_one_rounded_distribution_or_score} =
             Rounded.normalize([0, 1], :score, %{private: "secret"})
  end

  test "rounded policy preserves exact keys, legends and provider-confidence validation" do
    for body <- [
          put_in(response(), ["answers", "route", "probabilities"], %{
            "billing" => 0.8,
            "other" => 0.2
          }),
          put_in(response(), ["answers", "severity", "legend", "1"], "wrong"),
          put_in(response(), ["answers", "route", "confidence"], 1.1)
        ] do
      assert {:error, _} = rounded_decode(body)
    end
  end

  test "Qwen default policy uses the actual encoded model and strict override remains usable" do
    body =
      response()
      |> Map.put("model", "decision-model-preview")
      |> put_in(["answers", "route", "probabilities"], %{"billing" => 0.79, "technical" => 0.2})

    Mimic.expect(Finch, :request, 3, fn _, _, _ -> {:ok, reply(body)} end)
    assert {:ok, _} = Qwen.classify(request())

    assert {:error, :invalid_system_one_distribution} =
             Qwen.classify(request(), distribution_policy: :strict)

    overridden = %{request() | model: %GenAI.Model{model: "other-model", provider: Qwen}}

    assert {:error, :invalid_system_one_distribution} =
             Qwen.classify(overridden, distribution_policy: :alibaba_rounded_hundredths)
  end

  test "Alibaba policy keeps previously valid strict high-precision and large-choice responses" do
    body =
      response()
      |> put_in(["answers", "severity", "probabilities"], %{
        "0" => 0.123,
        "1" => 0.234,
        "2" => 0.643
      })
      |> put_in(["answers", "severity", "score"], 1.52)

    assert {:ok, result} = rounded_decode(body)
    refute Map.has_key?(Enum.at(result.answers, 2).metadata, :distribution_policy)

    choices = Enum.map(0..10, &Integer.to_string/1)

    {:ok, request} =
      Request.normalize(%Request{
        input: "synthetic",
        questions: [%Question{id: "pick", choices: choices}]
      })

    wire = %{
      "model" => "decision-model-preview",
      "answers" => %{
        "pick" => %{
          "type" => "choice",
          "choice" => "0",
          "probabilities" => Map.new(choices, &{&1, if(&1 == "0", do: 1.0, else: 0.0)})
        }
      }
    }

    assert {:ok, _} =
             SystemOne.decode(wire, request, Qwen,
               distribution_policy: :alibaba_rounded_hundredths
             )
  end

  test "live fork preparation uses the Core transformer callback contract and keeps branch history" do
    original = GenAI.Message.user("Synthetic ticket")
    thread = GenAI.chat(:session) |> GenAI.with_message(original)
    {:ok, pipeline} = GenAI.Pipeline.new(thread)

    %GenAI.Thread.Fork{branches: branches} =
      GenAI.Pipeline.fork(
        pipeline,
        Enum.map(["helpful", "unhelpful"], fn id ->
          {id,
           fn branch ->
             GenAI.Pipeline.transform(branch, fn thread, _options ->
               GenAI.with_message(thread, GenAI.Message.assistant(id))
             end)
           end}
        end)
      )

    assert length(branches) == 2

    for branch <- branches do
      assert is_nil(branch.error)
      messages = GenAI.Pipeline.Snapshot.messages(branch.pipeline.thread)
      assert hd(messages).content == "Synthetic ticket"
      assert List.last(messages).content == branch.id
    end
  end
end

defmodule GenAI.LocalClassifierTest do
  use ExUnit.Case, async: true
  alias GenAI.Classifier.{Question, Request}
  alias GenAI.Provider.Jev.Local

  defmodule Backend do
    def load_classifier(_, _, _), do: {:ok, :loaded}

    def classify(:loaded, request, options) do
      {:ok,
       %{
         answers: [
           %{
             question_id: hd(request.questions).id,
             index: 0,
             metadata: %{api_key: options[:api_key]}
           }
         ],
         usage: %{
           api_key: options[:api_key],
           total_tokens: %{api_key: options[:api_key]},
           prompt_tokens: 1,
           completion_tokens: -1
         },
         metadata: %{api_key: options[:api_key], forward_passes: 1}
       }}
    end
  end

  defmodule Failure do
    def load_classifier(_, _, _), do: {:error, "fixture-secret"}
    def classify(_, _, _), do: {:error, %{authorization: "fixture-secret"}}
  end

  defp request,
    do: %Request{
      input: "synthetic",
      model: Local.model(),
      questions: [%Question{id: "pick", choices: ["a", "b"]}]
    }

  test "loads and invokes optional backend without native imports or metadata leakage" do
    assert {:ok, :loaded} = Local.load("model", "head", backend: Backend)

    assert {:ok, result} =
             GenAI.classify(request(),
               backend: Backend,
               classifier: :loaded,
               api_key: "fixture-secret"
             )

    assert result.provider == Local
    assert result.metadata == %{forward_passes: 1}
    assert result.usage == %{prompt_tokens: 1}
    refute inspect(result) =~ "fixture-secret"
    refute inspect(result) =~ "api_key"
  end

  test "returns tagged missing-backend and missing-loaded-model errors" do
    assert {:error, :local_classifier_backend_unavailable} =
             Local.load("model", "head", backend: GenAI.UninstalledBackend)

    assert {:error, :loaded_local_classifier_required} = GenAI.classify(request())

    assert {:error, :local_classifier_backend_unavailable} =
             GenAI.classify(request(), backend: GenAI.UninstalledBackend, classifier: :loaded)
  end

  test "redacts native backend failures" do
    assert {:error, :local_classifier_inference_failed} =
             Local.load("model", "head", backend: Failure)

    assert {:error, :local_classifier_inference_failed} =
             GenAI.classify(request(), backend: Failure, classifier: :loaded)
  end
end
