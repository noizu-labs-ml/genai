defmodule ToborGradeTest do
  use ExUnit.Case, async: false

  alias GenAI.Classifier.{Question, Result}
  alias ToborGrade.Transcript

  defp fixture_transcript(tmp, turns) do
    events =
      Enum.map(turns, fn {user, assistant} ->
        user_line = Jason.encode!(%{type: "user", message: %{role: "user", content: user}})

        assistant_line =
          Jason.encode!(%{
            type: "assistant",
            message: %{
              role: "assistant",
              content: [
                %{"type" => "text", "text" => assistant},
                %{"type" => "tool_use", "name" => "Read"}
              ]
            }
          })

        tool_result_line =
          Jason.encode!(%{
            type: "user",
            message: %{role: "user", content: [%{"type" => "tool_result", "content" => "ok"}]}
          })

        Enum.join([user_line, assistant_line, tool_result_line], "\n")
      end)
      |> Enum.join("\n")

    path = Path.join(tmp, "transcript.jsonl")
    File.write!(path, events <> "\n")
    path
  end

  defp stub_router(responses) do
    {:ok, agent} = Agent.start_link(fn -> responses end)

    fn request ->
      [response | rest] = Agent.get(agent, & &1)
      Agent.update(agent, fn _ -> rest end)
      response.(request)
    end
  end

  defp choice_result(id, value) do
    {:ok,
     %Result{
       answers: [
         %Result.Answer{question_id: id, type: :choice, choice_id: value, value: value}
       ]
     }}
  end

  defp score_result(id, expected, grade) do
    {:ok,
     %Result{
       answers: [
         %Result.Answer{question_id: id, type: :score, grade: grade, expected_score: expected}
       ]
     }}
  end

  describe "argument validation" do
    test "missing --transcript is a usage error" do
      assert {:error, {:missing_argument, :transcript}} =
               ToborGrade.run(["--sink", "jsonl:/tmp/unused.jsonl"])
    end

    test "missing --sink is a usage error" do
      assert {:error, {:missing_argument, :sink}} =
               ToborGrade.run(["--transcript", "/tmp/unused.jsonl"])
    end

    test "non-jsonl sinks are rejected" do
      assert {:error, {:invalid_sink, _}} =
               ToborGrade.run(["--transcript", "/tmp/t.jsonl", "--sink", "csv:/tmp/t.csv"])
    end

    test "walkback above the cap is rejected" do
      assert {:error, {:invalid_walkback, {:cap, 5}}} =
               ToborGrade.run([
                 "--transcript",
                 "/tmp/t.jsonl",
                 "--sink",
                 "jsonl:/tmp/t.jsonl",
                 "--walkback",
                 "6"
               ])
    end

    test "non-integer walkback is rejected as an unknown argument" do
      assert {:error, {:unknown_arguments, [{"--walkback", "many"}]}} =
               ToborGrade.run([
                 "--transcript",
                 "/tmp/t.jsonl",
                 "--sink",
                 "jsonl:/tmp/t.jsonl",
                 "--walkback",
                 "many"
               ])
    end

    test "recursion guard refuses TOBOR_GRADING=1" do
      System.put_env("TOBOR_GRADING", "1")

      try do
        assert {:error, :grading_recursion_guard} =
                 ToborGrade.run(["--transcript", "/tmp/t.jsonl", "--sink", "jsonl:/tmp/t.jsonl"])
      after
        System.delete_env("TOBOR_GRADING")
      end
    end
  end

  describe "transcript handling" do
    @tag tmp_dir: true
    test "loads JSONL and renders roles, tools and results", %{tmp_dir: tmp} do
      path = fixture_transcript(tmp, [{"fix the button", "Reading app/src first."}])
      {:ok, events} = Transcript.load(path)

      rendered = Transcript.render(events)
      assert rendered =~ "user: fix the button"
      assert rendered =~ "assistant: Reading app/src first."
      assert rendered =~ "[tool call: Read]"
      assert rendered =~ "[tool result: ok]"
    end

    @tag tmp_dir: true
    test "walk_back drops newest real user turns, never tool-result echoes", %{tmp_dir: tmp} do
      path =
        fixture_transcript(tmp, [
          {"first task", "working"},
          {"second task", "working"},
          {"third task", "working"}
        ])

      {:ok, events} = Transcript.load(path)
      assert length(events) == 9

      {:ok, trimmed, remaining} = Transcript.walk_back(events, 1)
      assert remaining == 2
      rendered = Transcript.render(trimmed)
      assert rendered =~ "second task"
      refute rendered =~ "third task"

      # walking back every turn is refused — the first turn must survive
      assert {:error, :cannot_walk_back} = Transcript.walk_back(events, 3)
    end

    @tag tmp_dir: true
    test "malformed JSONL fails fast with the line number", %{tmp_dir: tmp} do
      path = Path.join(tmp, "bad.jsonl")
      File.write!(path, "{\"type\": \"user\"\n")
      assert {:error, {:invalid_transcript_line, 1}} = Transcript.load(path)
    end
  end

  describe "request construction" do
    test "choice lane targets jev-latest with the four verdicts" do
      assert {:ok, request} =
               ToborGrade.build_request("user: hello", %{score?: false, component: nil})

      assert request.model.model == "jev-latest"
      assert request.model.provider == GenAI.Provider.Jev

      assert [%Question{type: :choice, choices: choices, id: "verdict"}] = request.questions

      assert Enum.map(choices, & &1.id) == [
               "continuation",
               "topic-switch",
               "new-task",
               "more-context-needed"
             ]
    end

    test "score lane targets decision-model-preview with a 10-level 0-100 rubric" do
      assert {:ok, request} =
               ToborGrade.build_request("user: hello", %{score?: true, component: nil})

      assert request.model.model == "decision-model-preview"
      assert request.model.provider == GenAI.Provider.Qwen

      assert [%Question{type: :score, rubric: rubric, id: "quality"}] = request.questions
      assert length(rubric) == 10

      scores = Enum.map(rubric, & &1.score)
      assert scores == Enum.sort(Enum.uniq(scores))
      assert Enum.min(scores) == 0 and Enum.max(scores) == 100
    end
  end

  describe "grading runs" do
    @tag tmp_dir: true
    test "appends one schema-exact JSON line to the sink", %{tmp_dir: tmp} do
      transcript = fixture_transcript(tmp, [{"build the widget", "on it"}])
      sink = Path.join(tmp, "grades.jsonl")
      router = stub_router([fn _ -> choice_result("verdict", "continuation") end])

      {:ok, summary} =
        ToborGrade.run(
          [
            "--transcript",
            transcript,
            "--sink",
            "jsonl:" <> sink,
            "--component",
            "style-guide-btn"
          ],
          router: router
        )

      assert summary.verdict == "continuation"
      assert summary.walkback_used == 0

      [line] = File.read!(sink) |> String.split("\n", trim: true)
      decoded = Jason.decode!(line)

      assert decoded["verdict"] == "continuation"
      assert decoded["component"] == "style-guide-btn"
      assert decoded["transcript_path"] == transcript
      assert decoded["walkback_used"] == 0
      assert decoded["timestamp"]
      refute Map.has_key?(decoded, "score")
    end

    @tag tmp_dir: true
    test "walks back on more-context-needed up to the cap", %{tmp_dir: tmp} do
      transcript = fixture_transcript(tmp, [{"t1", "a"}, {"t2", "b"}, {"t3", "c"}])
      sink = Path.join(tmp, "grades.jsonl")

      responses = [
        fn _ -> choice_result("verdict", "more-context-needed") end,
        fn _ -> choice_result("verdict", "more-context-needed") end,
        fn _ -> choice_result("verdict", "topic-switch") end
      ]

      router = stub_router(responses)

      {:ok, summary} =
        ToborGrade.run(
          ["--transcript", transcript, "--sink", "jsonl:" <> sink, "--walkback", "5"],
          router: router
        )

      assert summary.verdict == "topic-switch"
      assert summary.walkback_used == 2

      decoded =
        sink |> File.read!() |> String.split("\n", trim: true) |> hd() |> Jason.decode!()

      assert decoded["walkback_used"] == 2
    end

    @tag tmp_dir: true
    test "walkback stops when only the first turn remains", %{tmp_dir: tmp} do
      transcript = fixture_transcript(tmp, [{"only", "turn"}])
      sink = Path.join(tmp, "grades.jsonl")

      router = stub_router([fn _ -> choice_result("verdict", "more-context-needed") end])

      {:ok, summary} =
        ToborGrade.run(
          ["--transcript", transcript, "--sink", "jsonl:" <> sink, "--walkback", "5"],
          router: router
        )

      assert summary.verdict == "more-context-needed"
      assert summary.walkback_used == 0
    end

    @tag tmp_dir: true
    test "score lane records the expected score", %{tmp_dir: tmp} do
      transcript = fixture_transcript(tmp, [{"component work", "shipped"}])
      sink = Path.join(tmp, "grades.jsonl")

      router = stub_router([fn _ -> score_result("quality", 72.4, "level-6") end])

      {:ok, summary} =
        ToborGrade.run(
          ["--transcript", transcript, "--sink", "jsonl:" <> sink, "--score"],
          router: router
        )

      assert summary.verdict == "level-6"
      assert summary.score == 72.4

      decoded =
        sink |> File.read!() |> String.split("\n", trim: true) |> hd() |> Jason.decode!()

      assert decoded["score"] == 72.4
      refute Map.has_key?(decoded, "component")
    end

    test "missing transcript file is an error" do
      assert {:error, {:transcript_read, _, _}} =
               ToborGrade.run([
                 "--transcript",
                 "/nonexistent/x.jsonl",
                 "--sink",
                 "jsonl:/tmp/unused.jsonl"
               ])
    end
  end
end
