defmodule GenAI.Provider.QwenTest do
  use ExUnit.Case
  import GenAI.Test.Support.Common

  @moduletag provider: :qwen

  setup do
    prev = Application.get_env(:genai, :qwen, [])

    Application.put_env(
      :genai,
      :qwen,
      Keyword.merge([api_key: "test-qwen-key"], prev)
    )

    on_exit(fn -> Application.put_env(:genai, :qwen, prev) end)
    :ok
  end

  describe "Qwen Provider" do
    test "models" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: ~s({
  "object": "list",
  "data": [
    {"id": "qwen3.8-max", "object": "model", "created": 1754000000, "owned_by": "alibaba"},
    {"id": "qwen-plus", "object": "model", "created": 1710000000, "owned_by": "alibaba"},
    {"id": "qwen-turbo", "object": "model", "created": 1710000000, "owned_by": "alibaba"}
  ]
}),
           headers: [{"content-type", "application/json"}],
           trailers: []
         }}
      end)

      {:ok, models} = GenAI.Provider.Qwen.models()
      sut = Enum.find(models, &(&1.model == "qwen3.8-max"))
      assert sut
      assert sut.provider == GenAI.Provider.Qwen
    end

    test "chat - basic completion" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: ~s({
  "id": "chatcmpl-qwen-abc123",
  "object": "chat.completion",
  "created": 1754000000,
  "model": "qwen3.8-max",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! How can I assist you today?"
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 9,
    "total_tokens": 19
  },
  "system_fingerprint": "fp_qwen_001"
}),
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.Qwen.Models.qwen3_8_max())
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_setting(:enable_thinking, false)
        |> GenAI.with_message(%GenAI.Message{role: :user, content: "Say Hello."})

      {:ok, sut} = GenAI.run(thread)
      choice = sut.choices |> hd()
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Hello! How can I assist you today?"
      assert choice.finish_reason == :stop
    end

    test "chat - with reasoning_content" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: ~s({
  "id": "chatcmpl-qwen-think123",
  "object": "chat.completion",
  "created": 1754000001,
  "model": "qwen3.8-max",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Stanley Kubrick directed 2001: A Space Odyssey.",
        "reasoning_content": "The user asked who directed the film."
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 20,
    "completion_tokens": 40,
    "total_tokens": 60
  }
}),
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.Qwen.Models.qwen3_8_max())
        |> GenAI.with_message(%GenAI.Message{
          role: :user,
          content: "Who directed 2001: A Space Odyssey?"
        })

      {:ok, sut} = GenAI.run(thread)
      choice = sut.choices |> hd()
      [thinking_part, text] = choice.message.content
      assert %GenAI.Message.Content.ThinkingContent{thinking: thinking} = thinking_part
      assert thinking =~ "directed"
      assert text.text =~ "Stanley Kubrick"
    end

    test "chat - with function calls" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: ~S({
  "id": "chatcmpl-qwen-tool123",
  "object": "chat.completion",
  "created": 1754000002,
  "model": "qwen3.8-max",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": null,
        "tool_calls": [
          {
            "id": "call_qwen_001",
            "type": "function",
            "function": {
              "name": "random_fact",
              "arguments": "{\"subject\":\"cats\"}"
            }
          }
        ]
      },
      "logprobs": null,
      "finish_reason": "tool_calls"
    }
  ],
  "usage": {
    "prompt_tokens": 70,
    "completion_tokens": 14,
    "total_tokens": 84
  }
}),
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.Qwen.Models.qwen3_8_max())
        |> GenAI.with_setting(:enable_thinking, false)
        |> GenAI.with_tool(random_fact_tool())
        |> GenAI.with_message(%GenAI.Message{
          role: :user,
          content: "Tell me a random fact about cats using a tool call."
        })

      {:ok, sut} = GenAI.run(thread)
      choice = sut.choices |> hd()
      assert choice.message.__struct__ == GenAI.Message.ToolUsage
      [tc] = choice.message.tool_calls
      assert tc.tool_name == "random_fact"
      assert tc.arguments[:subject] == "cats"
    end

    test "chat - with function call response" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: ~S({
  "id": "chatcmpl-qwen-tool456",
  "object": "chat.completion",
  "created": 1754000003,
  "model": "qwen3.8-max",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Here's a random fact about cats: \"Cats sleep up to 16 hours a day!\""
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 108,
    "completion_tokens": 22,
    "total_tokens": 130
  }
}),
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.Qwen.Models.qwen3_8_max())
        |> GenAI.with_setting(:enable_thinking, false)
        |> GenAI.with_tool(random_fact_tool())
        |> GenAI.with_message(%GenAI.Message{
          role: :user,
          content: "Tell me a random fact about cats using a tool call."
        })
        |> GenAI.with_message(%GenAI.Message.ToolUsage{
          role: :assistant,
          content: nil,
          tool_calls: [
            %GenAI.Message.ToolCall{
              id: "call_qwen_001",
              tool_name: "random_fact",
              arguments: %{subject: "cats"}
            }
          ],
          vsn: 1.0
        })
        |> GenAI.with_message(%GenAI.Message.ToolResponse{
          tool_response: %{body: "Cats sleep up to 16 hours a day!"},
          tool_call_id: "call_qwen_001"
        })

      {:ok, sut} = GenAI.run(thread)
      choice = sut.choices |> hd()
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content =~ "cats"
      assert choice.finish_reason == :stop
    end

    test "catalog paginates native /api/v1/models" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             ~s({"success":true,"output":{"total":2,"page_no":1,"page_size":1,"models":[{"model":"qwen3.8-max","capabilities":["TG"]}]}}),
           headers: [{"content-type", "application/json"}],
           trailers: []
         }}
      end)

      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             ~s({"success":true,"output":{"total":2,"page_no":2,"page_size":1,"models":[{"model":"qwen3.7-text-embedding","capabilities":["TR"]}]}}),
           headers: [{"content-type", "application/json"}],
           trailers: []
         }}
      end)

      {:ok, models} = GenAI.Provider.Qwen.catalog(page_size: 1)
      ids = Enum.map(models, & &1.model)
      assert "qwen3.8-max" in ids
      assert "qwen3.7-text-embedding" in ids
    end

    @tag :live
    @tag provider: :qwen
    test "live models list includes qwen3.8-max" do
      {:ok, models} = GenAI.Provider.Qwen.models()
      ids = Enum.map(models, & &1.model)
      assert "qwen3.8-max" in ids
    end

    @tag :live
    @tag provider: :qwen
    test "live catalog includes qwen3.7-text-embedding" do
      {:ok, models} = GenAI.Provider.Qwen.catalog(capabilities: "TR")
      ids = Enum.map(models, & &1.model)
      assert "qwen3.7-text-embedding" in ids
    end

    @tag :live
    @tag :advanced
    @tag provider: :qwen
    @tag thread: :session
    test "Advanced Context run - vnext session" do
      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.Qwen.Models.qwen3_8_max())
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_setting(:enable_thinking, false)
        |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL"})
        |> GenAI.with_message(%GenAI.Message{
          role: :assistant,
          content: "I'm afraid I can't do that Dave"
        })
        |> GenAI.with_message(%GenAI.Message{
          role: :user,
          content: "What is the movie \"2001: A Space Odyssey\" about and who directed it?"
        })

      {:ok, sut} = GenAI.run(thread)
      response = sut.choices |> hd()

      text =
        case response.message.content do
          bin when is_binary(bin) ->
            bin

          parts when is_list(parts) ->
            Enum.find_value(parts, fn
              %GenAI.Message.Content.TextContent{text: t} -> t
              %{text: t} when is_binary(t) -> t
              _ -> nil
            end)
        end

      assert text =~ "Stanley Kubrick"
    end
  end
end
