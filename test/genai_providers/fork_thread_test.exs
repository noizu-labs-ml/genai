defmodule GenAI.ForkThreadProviderTest do
  use ExUnit.Case, async: false
  use Mimic

  alias GenAI.Thread.Fork
  alias GenAI.Tool.Registry

  setup :set_mimic_global
  setup :verify_on_exit!

  defmodule Source do
    @behaviour GenAI.Tool.Source

    def list_tools(_, _, _),
      do: {:ok, [%{name: "lookup", parameters: %{type: "object"}}]}

    def call_tool(owner, "lookup", arguments, _, _) do
      send(owner, {:lookup, arguments})
      {:ok, %{answer: arguments["branch"]}}
    end
  end

  defp thread(name, api \\ :native, kind \\ :session) do
    model =
      if api == :native,
        do: GenAI.Provider.Qwen.Models.native(name),
        else: GenAI.Provider.Qwen.Models.model(name)

    GenAI.chat(kind)
    |> GenAI.with_model(model)
    |> GenAI.with_setting(:api_key, "fixture-key")
    |> GenAI.with_setting(:token_plan, false)
    |> GenAI.with_setting(:native_base_url, "https://fixture.example/api/v1")
    |> GenAI.with_setting(:base_url, "https://fixture.example/compatible-mode/v1")
    |> GenAI.with_message(GenAI.Message.user(name))
  end

  defp packet(name, message, finish \\ "stop") do
    %{
      request_id: "request-" <> name,
      output: %{choices: [%{message: message, finish_reason: finish}]},
      usage: %{input_tokens: 3, output_tokens: 2, total_tokens: 5}
    }
  end

  defp fork do
    GenAI.Pipeline.fork(thread("initial"),
      native: fn pipeline -> %{pipeline | thread: thread("native-branch", :native, :standard)} end,
      compatible: fn pipeline ->
        %{pipeline | thread: thread("compatible-branch", :compatible)}
      end
    )
  end

  test "public run dispatches independent models through native and compatible provider encoders" do
    owner = self()

    stub(Finch, :request, fn request, GenAI.Finch, _ ->
      body = Jason.decode!(request.body)
      name = body["model"]
      send(owner, {:request, name, request.path})

      response =
        if name == "native-branch" do
          assert body["input"]["messages"] == [%{"role" => "user", "content" => name}]
          packet(name, %{role: "assistant", content: name})
        else
          assert body["messages"] == [%{"role" => "user", "content" => name}]

          %{
            id: "request-" <> name,
            object: "chat.completion",
            created: 1_760_000_000,
            model: name,
            usage: %{prompt_tokens: 3, completion_tokens: 2, total_tokens: 5},
            choices: [
              %{index: 0, message: %{role: "assistant", content: name}, finish_reason: "stop"}
            ]
          }
        end

      {:ok, %Finch.Response{status: 200, body: Jason.encode!(response)}}
    end)

    assert %Fork{} = fork = fork()
    assert {:ok, {%Fork.Result{} = result, %Fork{} = updated}} = GenAI.run(fork, nil, [])
    assert Enum.map(result.outcomes, & &1.path) == [[:native], [:compatible]]
    assert Enum.all?(result.outcomes, &(&1.status == :ok))

    assert Enum.map(result.outcomes, & &1.value.id) == [
             "request-native-branch",
             "request-compatible-branch"
           ]

    assert_receive {:request, "native-branch", "/api/v1/services/aigc/text-generation/generation"}
    assert_receive {:request, "compatible-branch", "/compatible-mode/v1/chat/completions"}
    assert {:ok, {models, %Fork{}}} = GenAI.ThreadProtocol.effective_model(updated, nil, [])
    assert %Fork.Result{outcomes: model_outcomes} = models

    assert Enum.map(model_outcomes, &{&1.path, &1.value.model}) == [
             {[:native], "native-branch"},
             {[:compatible], "compatible-branch"}
           ]
  end

  test "native tool chain replays each branch's tool result through its own HTTP continuation" do
    owner = self()
    {:ok, registry} = Registry.register(Registry.new(), :facts, Source, owner)

    stub(Finch, :request, fn request, GenAI.Finch, _ ->
      body = Jason.decode!(request.body)
      name = body["model"]
      messages = body["input"]["messages"]
      tool_results = Enum.filter(messages, &(&1["role"] == "tool"))

      {message, finish} =
        if tool_results == [] do
          {%{
             role: "assistant",
             content: "",
             tool_calls: [
               %{
                 id: "call-" <> name,
                 type: "function",
                 function: %{name: "facts__lookup", arguments: Jason.encode!(%{branch: name})}
               }
             ]
           }, "tool_calls"}
        else
          assert [%{"tool_call_id" => call_id, "content" => content}] = tool_results
          assert call_id == "call-" <> name
          assert Jason.decode!(content) == %{"answer" => name}
          send(owner, {:continued, name})
          {%{role: "assistant", content: "done-" <> name}, "stop"}
        end

      {:ok, %Finch.Response{status: 200, body: Jason.encode!(packet(name, message, finish))}}
    end)

    fork =
      GenAI.Pipeline.fork(thread("left", :native, :standard),
        left: & &1,
        right: fn pipeline -> %{pipeline | thread: thread("right")} end
      )

    assert {:ok, {%Fork.Result{} = result, %Fork{} = updated}} =
             GenAI.run_with_tools(fork, registry, nil, [])

    assert Enum.map(result.outcomes, & &1.path) == [[:left], [:right]]

    for outcome <- result.outcomes do
      assert outcome.status == :ok
      assert outcome.value.summary.iterations == 2
      assert outcome.value.summary.tool_calls == 1
      assert outcome.value.summary.stop_reason == :complete
    end

    assert_receive {:lookup, %{"branch" => "left"}}
    assert_receive {:lookup, %{"branch" => "right"}}
    assert_receive {:continued, "left"}
    assert_receive {:continued, "right"}

    assert {:ok, {models, updated}} = GenAI.ThreadProtocol.effective_model(updated, nil, [])

    assert {:ok, {%Fork.Result{outcomes: messages}, %Fork{}}} =
             GenAI.ThreadProtocol.effective_messages(updated, models, nil, [])

    for outcome <- messages do
      assert Enum.count(outcome.value, &(&1.role == "tool")) == 1
    end
  end

  test "nested native streams carry full branch paths and independent accumulators" do
    owner = self()

    stub(Finch, :stream_while, fn request, GenAI.Finch, state, callback, _ ->
      body = Jason.decode!(request.body)
      name = body["model"]
      {:cont, state} = callback.({:status, 200}, state)

      data =
        "data: " <> Jason.encode!(packet(name, %{role: "assistant", content: name})) <> "\n\n"

      {:cont, state} = callback.({:data, data}, state)
      send(owner, {:streamed, name})
      {:ok, state}
    end)

    fork =
      GenAI.Pipeline.fork(thread("root"),
        direct: fn pipeline -> %{pipeline | thread: thread("direct")} end,
        nested: fn _ -> GenAI.Pipeline.split(thread("nested"), 2) end
      )

    assert {:ok, {%Fork.Result{} = result, %Fork{}}} =
             GenAI.stream(fork, nil, stream_sink: self(), max_concurrency: 2)

    assert Enum.map(result.outcomes, & &1.path) == [[:direct], [:nested, 0], [:nested, 1]]
    assert Enum.map(result.outcomes, & &1.value.text) == ["direct", "nested", "nested"]
    assert Enum.all?(result.outcomes, & &1.value.completed)
    assert_receive {:genai, {:branch, [:direct], {:text, "direct"}}}
    assert_receive {:genai, {:branch, [:nested, 0], {:text, "nested"}}}
    assert_receive {:genai, {:branch, [:nested, 1], {:text, "nested"}}}
    refute_receive {:genai, {:text, _}}, 0
  end

  test "a provider failure returns successful sibling completion and redacted branch error" do
    stub(Finch, :request, fn request, GenAI.Finch, _ ->
      name = Jason.decode!(request.body)["model"]

      if name == "failed" do
        {:ok, %Finch.Response{status: 401, body: "private provider response"}}
      else
        {:ok,
         %Finch.Response{
           status: 200,
           body: Jason.encode!(packet(name, %{role: "assistant", content: "ok"}))
         }}
      end
    end)

    fork =
      GenAI.Pipeline.fork(thread("success"),
        success: & &1,
        failed: fn pipeline -> %{pipeline | thread: thread("failed")} end
      )

    assert {:error, %Fork.Error{result: result, fork: %Fork{}} = error} = GenAI.run(fork, nil, [])

    assert [
             %{path: [:success], status: :ok, value: %GenAI.ChatCompletion{}},
             %{path: [:failed], status: :error, reason: {:dashscope_http_error, 401}}
           ] = result.outcomes

    refute inspect(error) =~ "private"
  end

  test "configured Accumulate sinks preserve branch identity and handler continuation" do
    handler = %GenAI.StreamHandler.Accumulate{sink: self()}
    original = GenAI.with_stream_handler(thread("configured", :native, :standard), handler)
    fork = GenAI.Pipeline.split(original, 2)

    stub(Finch, :stream_while, fn _, GenAI.Finch, state, callback, _ ->
      {:cont, state} = callback.({:status, 200}, state)

      {:cont, state} =
        callback.(
          {:data,
           "data: " <>
             Jason.encode!(packet("configured", %{role: "assistant", content: "text"})) <> "\n\n"},
          state
        )

      {:ok, state}
    end)

    assert {:ok, {%Fork.Result{} = result, updated}} = GenAI.stream(fork, nil, [])
    assert Enum.map(result.outcomes, & &1.value.text) == ["text", "text"]
    assert_receive {:genai, {:branch, [0], {:text, "text"}}}
    assert_receive {:genai, {:branch, [1], {:text, "text"}}}
    refute_receive {:genai, {:text, _}}, 0

    assert {:ok, {%Fork.Result{outcomes: settings}, _}} =
             GenAI.ThreadProtocol.effective_settings(updated, nil, [])

    assert Enum.all?(settings, &(&1.value[:stream_handler] == handler))
  end
end
