defmodule GenAI.QwenNativeTest.CustomHandler do
  defstruct [:sink]

  def begin_stream(handler, session, _, _) do
    callback = fn event, state ->
      send(state.sink, {:custom, event})
      action = if match?({:data, _}, event), do: :halt, else: :cont
      {action, state}
    end

    {:ok, {{handler, callback}, session}}
  end
end

defmodule GenAI.QwenNativeTest do
  use ExUnit.Case, async: false
  use Mimic
  setup :set_mimic_private
  setup :verify_on_exit!

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

  alias GenAI.Provider.Qwen.Native.{
    Encoder,
    Messages,
    Response,
    StreamDecoder,
    StreamHandler,
    SSE
  }

  alias GenAI.Message.Content

  defp model(api \\ :text), do: GenAI.Provider.Qwen.Models.native("qwen-plus", api: api)

  defp settings(values \\ []),
    do: %{settings: values, model_settings: [], provider_settings: [], config_settings: []}

  defp packet(
         message \\ %{role: "assistant", content: "Hello"},
         usage \\ %{input_tokens: 3, output_tokens: 2, total_tokens: 5}
       ),
       do: %{
         request_id: "req-1",
         output: %{choices: [%{message: message, finish_reason: "stop"}]},
         usage: usage
       }

  defp start_stream do
    {:ok, {{state, _}, _}} =
      StreamHandler.begin_stream(nil, :session, nil,
        stream_sink: self(),
        stream_model: "qwen-plus",
        stream_provider: GenAI.Provider.Qwen.Native
      )

    {:cont, state} = StreamHandler.handle_event({:status, 200}, state)
    state
  end

  test "native selection leaves compatible-mode constructor unchanged" do
    assert GenAI.Provider.Qwen.Models.model("qwen-plus").encoder == GenAI.Provider.Qwen.Encoder
    assert model().encoder == Encoder
    assert model().provider == GenAI.Provider.Qwen.Native
  end

  test "regional workspace native URLs append exactly once and reject other API styles" do
    for region <- [
          "cn-beijing",
          "ap-southeast-1",
          "us-east-1",
          "eu-central-1",
          "ap-northeast-1",
          "cn-hongkong"
        ] do
      root = "https://workspace.#{region}.maas.aliyuncs.com/api/v1"
      assert {:ok, ^root} = Encoder.native_root(root <> "/")

      assert {:ok, {{:post, endpoint}, :session}} =
               Encoder.endpoint(model(), settings(native_base_url: root), :session, nil, [])

      assert endpoint == root <> "/services/aigc/text-generation/generation"
    end

    assert {:error, :missing_native_base_url} = Encoder.native_root(nil)

    assert {:error, :invalid_native_base_url} =
             Encoder.native_root("https://example.test/compatible-mode/v1")

    assert {:error, :invalid_native_base_url} =
             Encoder.native_root("https://key@example.test/api/v1")

    assert {:error, :invalid_native_base_url} =
             Encoder.native_root("https://example.test/api/v1?api_key=secret")
  end

  test "native envelope nests tools, schema and thinking parameters without body stream" do
    tools = [%{type: "function", function: %{name: "lookup", parameters: %{type: "object"}}}]

    schema = %{
      type: "json_schema",
      json_schema: %{name: "result", schema: %{type: "object"}, strict: true}
    }

    s =
      settings(
        stream: true,
        enable_thinking: false,
        response_format: schema,
        tool_choice: "auto",
        thinking_budget: 100,
        parallel_tool_calls: true,
        incremental_output: false
      )

    assert {:ok, {body, :session}} =
             Encoder.request_body(
               model(),
               [%{role: "user", content: "JSON please"}],
               tools,
               s,
               :session,
               nil,
               []
             )

    assert body.input.messages == [%{role: "user", content: "JSON please"}]
    assert body.parameters.tools == tools
    assert body.parameters.response_format == schema
    assert body.parameters.enable_thinking == false
    assert body.parameters.result_format == "message"
    assert body.parameters.incremental_output == true
    refute Map.has_key?(body, :stream)
    refute Map.has_key?(body.parameters, :stream)
    assert body.parameters.parallel_tool_calls
  end

  test "native bearer and streaming header use configured key and reject token plan" do
    assert {:ok, {headers, _}} =
             Encoder.headers(
               model(),
               settings(api_key: "fixture-key", stream: true),
               nil,
               nil,
               []
             )

    assert {"authorization", "Bearer fixture-key"} in headers
    assert {"X-DashScope-SSE", "enable"} in headers

    assert {:error, :native_token_plan_not_supported} =
             Encoder.headers(model(), settings(token_plan: true), nil, nil, [])
  end

  test "history keeps reasoning separate and opt-out removes it" do
    msg =
      GenAI.Message.assistant([
        %Content.ThinkingContent{thinking: "reason"},
        %Content.TextContent{text: "answer"}
      ])

    assert {:ok, encoded} = Messages.encode(msg)
    assert encoded.content == "answer"
    assert encoded.reasoning_content == "reason"

    assert {:ok, {body, _}} =
             Encoder.request_body(model(), [encoded], [], settings(), nil, nil, [])

    assert hd(body.input.messages).reasoning_content == "reason"

    assert {:ok, {body, _}} =
             Encoder.request_body(
               model(),
               [encoded],
               [],
               settings(preserve_thinking: false),
               nil,
               nil,
               []
             )

    refute Map.has_key?(hd(body.input.messages), :reasoning_content)
  end

  test "native multimodal sends native image parts and never drops unsupported audio" do
    msg =
      GenAI.Message.user([
        %Content.TextContent{text: "describe"},
        %Content.ImageContent{resource: {:uri, "https://example.test/image.png"}, type: :png}
      ])

    assert {:ok, encoded} = Messages.encode(msg)

    assert {:error, :multimodal_model_required} =
             Encoder.request_body(model(), [encoded], [], settings(), nil, nil, [])

    assert {:ok, {body, _}} =
             Encoder.request_body(model(:multimodal), [encoded], [], settings(), nil, nil, [])

    assert hd(body.input.messages).content == [
             %{text: "describe"},
             %{image: "https://example.test/image.png"}
           ]

    assert {:ok, {{:post, endpoint}, _}} =
             Encoder.endpoint(
               model(:multimodal),
               settings(native_base_url: "https://example.test/api/v1"),
               nil,
               nil,
               []
             )

    assert String.ends_with?(endpoint, "/multimodal-generation/generation")

    assert {:error, :unsupported_native_audio_content} =
             Messages.encode(
               GenAI.Message.user([%Content.AudioContent{transcript: "must not replace audio"}])
             )

    assert {:error, :unsupported_native_output_content} =
             StreamDecoder.chunk(packet(%{role: "assistant", content: [%{audio: "unexpected"}]}))

    assert {:error, :unsupported_native_content} =
             Messages.encode(GenAI.Message.user([%{private: "do not stringify"}]))
  end

  test "base64 images retain media type and multiple text parts become native text" do
    assert {:ok, encoded} =
             Messages.encode(
               GenAI.Message.user([
                 %Content.ImageContent{resource: {:base64, "YWJj"}, type: :jpeg}
               ])
             )

    assert encoded.content == [%{image: "data:image/jpeg;base64,YWJj"}]

    assert {:ok, encoded} =
             Messages.encode(
               GenAI.Message.user([
                 %Content.TextContent{text: "a"},
                 %Content.TextContent{text: "b"}
               ])
             )

    assert {:ok, {body, _}} =
             Encoder.request_body(model(), [encoded], [], settings(), nil, nil, [])

    assert hd(body.input.messages).content == "a\nb"
  end

  test "tool invocation and response correlate JSON string arguments and content" do
    call = %GenAI.Message.ToolCall{id: "call-1", tool_name: "lookup", arguments: %{"x" => 1}}

    assert {:ok, encoded} =
             Messages.encode(
               GenAI.Message.ToolUsage.new(role: :assistant, content: nil, tool_calls: [call])
             )

    assert hd(encoded.tool_calls).function.arguments == "{\"x\":1}"

    response =
      GenAI.Message.ToolResponse.new(tool_call_id: "call-1", tool_response: %{answer: 42})

    assert {:ok, %{role: "tool", tool_call_id: "call-1", content: "{\"answer\":42}"}} =
             Messages.encode(response)
  end

  test "completion maps native request ID, usage, reasoning and content" do
    p = packet(%{role: "assistant", content: [%{text: "Hello"}], reasoning_content: "reason"})
    assert {:ok, completion} = Response.completion(p, model())
    assert completion.id == "req-1"
    assert completion.usage.prompt_tokens == 3
    assert completion.usage.completion_tokens == 2
    assert completion.usage.total_tokens == 5

    assert [%Content.ThinkingContent{thinking: "reason"}, %Content.TextContent{text: "Hello"}] =
             hd(completion.choices).message.content
  end

  test "completion tool arguments stay string keys and malformed output returns typed errors" do
    p =
      packet(%{
        role: "assistant",
        content: "",
        tool_calls: [
          %{
            id: "c",
            type: "function",
            function: %{name: "lookup", arguments: "{\"never_atomize\":1}"}
          }
        ]
      })

    assert {:ok, completion} = Response.completion(p, model())
    assert hd(hd(completion.choices).message.tool_calls).arguments == %{"never_atomize" => 1}

    p =
      put_in(
        p,
        [
          :output,
          :choices,
          Access.at(0),
          :message,
          :tool_calls,
          Access.at(0),
          :function,
          :arguments
        ],
        "not-json"
      )

    assert {:error, :invalid_native_tool_call} = Response.completion(p, model())

    assert {:error, :dashscope_api_error} =
             Response.completion(%{code: "InvalidApiKey", message: "private response"}, model())

    assert {:error, :invalid_native_output} = Response.completion(%{output: %{}}, model())
  end

  test "incremental decoder keeps text, reasoning and tool argument fragments separate" do
    p =
      packet(%{
        role: "assistant",
        content: "hi",
        reasoning_content: "think",
        tool_calls: [
          %{
            index: 0,
            id: "c",
            type: "function",
            function: %{name: "lookup", arguments: "{\"x\":"}
          }
        ]
      })

    events = StreamDecoder.stream_event(p)
    assert {:text, "hi"} in events
    assert {:thinking, "think"} in events
    assert {:finish, :stop} in events

    assert {:tool_call, [%{index: 0, function: %{arguments: "{\"x\":"}}]} =
             Enum.find(events, &(elem(&1, 0) == :tool_call))
  end

  test "usage-only frame updates usage without fabricated text or finish" do
    assert [{:usage, %{prompt_tokens: 9, completion_tokens: 4, total_tokens: 13}}] =
             StreamDecoder.stream_event(%{
               usage: %{input_tokens: 9, output_tokens: 4, total_tokens: 13},
               output: %{choices: []}
             })

    assert Response.usage(%{
             input_tokens: %{api_key: "secret"},
             output_tokens: -1,
             total_tokens: 2
           }) == %{total_tokens: 2}
  end

  test "split CRLF and multiline data are preserved at every byte boundary" do
    payload =
      "event: result\r\ndata: {\r\ndata: \"output\": {\"choices\": [{\"message\":{\"role\":\"assistant\",\"content\":\"hello\"},\"finish_reason\":\"stop\"}]}}\r\n\r\n"

    for cut <- 0..byte_size(payload) do
      {a, b} = :erlang.split_binary(payload, cut)
      {first, state} = SSE.feed(SSE.new(), a)
      {last, state} = SSE.feed(state, b)
      assert [%{event: "result", data: data}] = first ++ last
      assert {:ok, _} = Jason.decode(data)
      assert state.buffer == ""
    end
  end

  test "native event:error plus numeric status halts with redacted error" do
    state = start_stream()

    assert {:halt, state} =
             StreamHandler.handle_event(
               {:data, "event:error\nstatus:429\ndata:{\"message\":\"private secret\"}\n\n"},
               state
             )

    assert state.acc.error == {:dashscope_stream_error, 429}
    refute inspect(state) =~ "private secret"
    assert {:error, {:dashscope_stream_error, 429}} = StreamHandler.finish(state)
  end

  test "JSON error in a 200 SSE response is surfaced" do
    assert {:halt, state} =
             StreamHandler.handle_event(
               {:data,
                "data: " <> Jason.encode!(%{code: "Denied", message: "private"}) <> "\n\n"},
               start_stream()
             )

    assert state.acc.error == :dashscope_stream_error
  end

  test "event done and HTTP close without DONE both preserve completion" do
    payload = "data: " <> Jason.encode!(packet())
    assert {:cont, state} = StreamHandler.handle_event({:data, payload}, start_stream())
    assert {:ok, acc} = StreamHandler.finish(state)
    assert acc.text == "Hello"
    assert acc.completed
    assert_receive {:genai, {:text, "Hello"}}

    assert {:cont, state} =
             StreamHandler.handle_event(
               {:data, payload <> "\n\nevent:done\ndata:{}\n\n"},
               start_stream()
             )

    assert {:ok, acc} = StreamHandler.finish(state)
    assert acc.completed
    assert acc.text == "Hello"
  end

  test "malformed frame and HTTP failures never look like inference success" do
    assert {:halt, state} =
             StreamHandler.handle_event({:data, "data: {invalid}\n\n"}, start_stream())

    assert {:error, :dashscope_stream_error} = StreamHandler.finish(state)
    {:cont, state} = StreamHandler.handle_event({:status, 401}, start_stream())
    assert {:error, {:dashscope_http_error, 401}} = StreamHandler.finish(state)
  end

  test "max token controls and false preserve_thinking are explicit native parameters" do
    assert {:ok, {body, _}} =
             Encoder.request_body(
               model(),
               [%{role: "user", content: "hello"}],
               [],
               settings(max_tokens: 10, max_completion_tokens: 20, preserve_thinking: false),
               nil,
               nil,
               []
             )

    assert body.parameters.max_tokens == 10
    assert body.parameters.max_completion_tokens == 20
    assert body.parameters.preserve_thinking == false
  end

  test "string tool results remain literal and invalid structured results reject safely" do
    response =
      GenAI.Message.ToolResponse.new(tool_call_id: "c", tool_response: "literal tool output")

    assert {:ok, %{content: "literal tool output"}} = Messages.encode(response)

    bad =
      GenAI.Message.ToolResponse.new(
        tool_call_id: "c",
        tool_response: %{private_function: fn -> :secret end}
      )

    assert {:error, :invalid_native_tool_result} = Messages.encode(bad)
  end

  test "stream completion retains reasoning-only and assembled tool-only messages" do
    payload = packet(%{role: "assistant", content: "", reasoning_content: "reason"})

    {:cont, state} =
      StreamHandler.handle_event(
        {:data, "data: " <> Jason.encode!(payload) <> "\n\n"},
        start_stream()
      )

    assert {:ok, acc} = StreamHandler.finish(state)

    assert [%Content.ThinkingContent{thinking: "reason"}] =
             hd(acc.completion.choices).message.content

    assert acc.completion.id == "req-1"

    frames = [
      packet(%{
        role: "assistant",
        content: "",
        tool_calls: [
          %{
            id: "c",
            index: 0,
            type: "function",
            function: %{name: "lookup", arguments: "{\"x\":"}
          }
        ]
      }),
      packet(%{
        role: "assistant",
        content: "",
        tool_calls: [
          %{id: "c", index: 0, type: "function", function: %{name: "lookup", arguments: "1}"}}
        ]
      })
    ]

    state =
      Enum.reduce(frames, start_stream(), fn frame, state ->
        {:cont, state} =
          StreamHandler.handle_event({:data, "data: " <> Jason.encode!(frame) <> "\n\n"}, state)

        state
      end)

    assert {:ok, acc} = StreamHandler.finish(state)

    assert [%GenAI.Message.ToolCall{id: "c", tool_name: "lookup", arguments: %{"x" => 1}}] =
             hd(acc.completion.choices).message.tool_calls
  end

  test "incomplete tool JSON and errors after partial content cannot become successful completion" do
    payload =
      packet(%{
        role: "assistant",
        content: "",
        tool_calls: [
          %{id: "c", index: 0, type: "function", function: %{name: "lookup", arguments: "{"}}
        ]
      })

    {:cont, state} =
      StreamHandler.handle_event(
        {:data, "data: " <> Jason.encode!(payload) <> "\n\n"},
        start_stream()
      )

    assert {:error, :invalid_native_tool_call} = StreamHandler.finish(state)

    {:cont, state} =
      StreamHandler.handle_event(
        {:data, "data: " <> Jason.encode!(packet()) <> "\n\n"},
        start_stream()
      )

    {:halt, state} =
      StreamHandler.handle_event({:data, "event:error\nstatus:503\ndata:{}\n\n"}, state)

    assert {:error, {:dashscope_stream_error, 503}} = StreamHandler.finish(state)
  end

  test "repeated cumulative usage updates replace counts rather than adding" do
    state =
      Enum.reduce(
        [
          %{input_tokens: 3, output_tokens: 1, total_tokens: 4},
          %{input_tokens: 3, output_tokens: 4, total_tokens: 7}
        ],
        start_stream(),
        fn usage, state ->
          {:cont, state} =
            StreamHandler.handle_event(
              {:data, "data: " <> Jason.encode!(%{usage: usage}) <> "\n\n"},
              state
            )

          state
        end
      )

    assert {:ok, acc} = StreamHandler.finish(state)
    assert acc.completion.usage.total_tokens == 7
    assert acc.completion.usage.completion_tokens == 4
  end

  defp thread do
    GenAI.chat(:session)
    |> GenAI.with_model(model())
    |> GenAI.with_setting(:api_key, "fixture-key")
    |> GenAI.with_setting(:native_base_url, "https://workspace.example.test/api/v1")
    |> GenAI.with_message(GenAI.Message.user("synthetic test"))
  end

  test "GenAI.run uses native model encoder and returns real completion contract" do
    expect(Finch, :request, fn request, GenAI.Finch, _ ->
      assert request.path == "/api/v1/services/aigc/text-generation/generation"
      body = Jason.decode!(request.body)
      assert body["input"]["messages"] == [%{"role" => "user", "content" => "synthetic test"}]
      assert body["parameters"]["result_format"] == "message"
      {:ok, %Finch.Response{status: 200, body: Jason.encode!(packet())}}
    end)

    assert {:ok, {%GenAI.ChatCompletion{} = completion, _}} = GenAI.run(thread(), nil, [])
    assert completion.id == "req-1"
    assert hd(completion.choices).message.role == :assistant
  end

  test "native provider converts non-200 successful Finch transport to redacted error" do
    expect(Finch, :request, fn _, _, _ ->
      {:ok,
       %Finch.Response{
         status: 401,
         body: "private-body",
         headers: [{"authorization", "private-key"}]
       }}
    end)

    result = GenAI.run(thread(), nil, [])
    assert result == {:error, {:dashscope_http_error, 401}}
    refute inspect(result) =~ "private"
  end

  test "GenAI.stream preserves Accumulate sink and returned handler across compatible switch" do
    original = GenAI.with_stream_handler(thread(), %GenAI.StreamHandler.Accumulate{sink: self()})

    expect(Finch, :stream_while, fn request, GenAI.Finch, state, callback, _ ->
      assert request.path == "/api/v1/services/aigc/text-generation/generation"
      assert {"X-DashScope-SSE", "enable"} in request.headers
      assert Jason.decode!(request.body)["parameters"]["incremental_output"] == true
      {:cont, state} = callback.({:status, 200}, state)
      {:cont, state} = callback.({:data, "data: " <> Jason.encode!(packet()) <> "\n\n"}, state)
      {:ok, state}
    end)

    assert {:ok, {acc, returned}} = GenAI.stream(original, nil, [])
    assert acc.completion.id == "req-1"
    assert_receive {:genai, {:text, "Hello"}}
    assert {:ok, {settings, _}} = GenAI.ThreadProtocol.effective_settings(returned, nil, [])
    assert settings[:stream_handler] == %GenAI.StreamHandler.Accumulate{sink: self()}
    compatible = returned |> GenAI.with_model(GenAI.Provider.Qwen.Models.model("qwen-plus"))

    expect(Finch, :stream_while, fn request, GenAI.Finch, state, callback, _ ->
      assert request.path == "/compatible-mode/v1/chat/completions"
      {:cont, state} = callback.({:status, 200}, state)

      {:cont, state} =
        callback.(
          {:data,
           "data: " <>
             Jason.encode!(%{
               choices: [%{delta: %{content: "compatible"}, finish_reason: "stop"}]
             }) <> "\n\n"},
          state
        )

      {:ok, state}
    end)

    assert {:ok, {_acc, _}} = GenAI.stream(compatible, nil, [])
    assert_receive {:genai, {:text, "compatible"}}
  end

  test "requested custom handler callback remains active under native framing" do
    handler = %GenAI.QwenNativeTest.CustomHandler{sink: self()}

    {:ok, {{state, _}, _}} =
      StreamHandler.begin_stream(nil, nil, nil, native_stream_handler: handler)

    {:cont, state} = StreamHandler.handle_event({:status, 200}, state)
    assert_receive {:custom, {:status, 200}}

    {:halt, _} =
      StreamHandler.handle_event({:data, "data: " <> Jason.encode!(packet()) <> "\n\n"}, state)

    assert_receive {:custom, {:data, _}}
  end

  test "finish reasons use bounded native mapping without atomizing unknown values" do
    for {reason, mapped} <- [
          {"stop", :stop},
          {"length", :max_tokens},
          {"tool_calls", :tool_call},
          {"unknown-untrusted-value", :unknown}
        ] do
      p = put_in(packet(), [:output, :choices, Access.at(0), :finish_reason], reason)
      assert {:ok, completion} = Response.completion(p, model())
      assert hd(completion.choices).finish_reason == mapped
    end
  end

  test "compatible request keeps nonempty tools and forced tool choice in the published body" do
    tool = %{type: "function", function: %{name: "lookup_ticket", parameters: %{type: "object"}}}
    choice = %{type: "function", function: %{name: "lookup_ticket"}}
    m = GenAI.Provider.Qwen.Models.model("qwen-plus")

    assert {:ok, {body, _}} =
             GenAI.Provider.Qwen.Encoder.request_body(
               m,
               [%{role: "user", content: "synthetic"}],
               [tool],
               settings(tool_choice: choice),
               nil,
               nil,
               []
             )

    assert body.tools == [tool]
    assert body.tool_choice == choice
  end

  test "empty repeated stream ID and name never erase earlier function identity" do
    frames = [
      packet(%{
        role: "assistant",
        content: "",
        tool_calls: [
          %{
            id: "actual-id",
            index: 0,
            type: "function",
            function: %{name: "lookup_ticket", arguments: "{\"ticket_id\":"}
          }
        ]
      }),
      packet(%{
        role: "assistant",
        content: "",
        tool_calls: [%{id: "", index: 0, type: nil, function: %{name: "", arguments: "\"T-1\"}"}}]
      })
    ]

    expect(Finch, :stream_while, fn _, GenAI.Finch, state, callback, _ ->
      {:cont, state} = callback.({:status, 200}, state)

      state =
        Enum.reduce(frames, state, fn frame, state ->
          {:cont, state} = callback.({:data, "data: " <> Jason.encode!(frame) <> "\n\n"}, state)
          state
        end)

      {:ok, state}
    end)

    assert {:ok, {acc, _}} = GenAI.stream(thread(), nil, [])

    assert [
             %GenAI.Message.ToolCall{
               id: "actual-id",
               tool_name: "lookup_ticket",
               arguments: %{"ticket_id" => "T-1"}
             }
           ] = hd(acc.completion.choices).message.tool_calls
  end
end
