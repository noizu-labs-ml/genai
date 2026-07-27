defmodule GenAI.Provider.ZAITest do
  use ExUnit.Case
  import GenAI.Test.Support.Common

  @moduletag provider: :zai

  def priv() do
    :code.priv_dir(:genai) |> List.to_string()
  end

  describe "ZAI Provider" do
    test "chat - basic completion" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: ~s({
  "id": "chatcmpl-zai-abc123",
  "object": "chat.completion",
  "created": 1713700000,
  "model": "glm-4.5-air",
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
  "system_fingerprint": "fp_zai_001"
}),
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.ZAI.Models.glm_4_5_air())
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_message(%GenAI.Message{role: :user, content: "Say Hello."})

      {:ok, sut} = GenAI.run(thread)
      choice = sut.choices |> hd()
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Hello! How can I assist you today?"
      assert choice.finish_reason == :stop
    end

    test "chat - with function calls" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: ~s({
  "id": "chatcmpl-zai-tool123",
  "object": "chat.completion",
  "created": 1713700001,
  "model": "glm-4.5-air",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": null,
        "tool_calls": [
          {
            "id": "call_zai_001",
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
  },
  "system_fingerprint": "fp_zai_001"
}),
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.ZAI.Models.glm_4_5_air())
        |> GenAI.with_tool(random_fact_tool())
        |> GenAI.with_message(%GenAI.Message{
          role: :user,
          content: "Tell me a random fact about cats using a tool call."
        })

      {:ok, sut} = GenAI.run(thread)
      choice = sut.choices |> hd()
      assert choice.index == 0
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
           body: ~s({
  "id": "chatcmpl-zai-tool456",
  "object": "chat.completion",
  "created": 1713700002,
  "model": "glm-4.5-air",
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
  },
  "system_fingerprint": "fp_zai_001"
}),
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.ZAI.Models.glm_4_5_air())
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
              id: "call_zai_001",
              tool_name: "random_fact",
              arguments: %{subject: "cats"}
            }
          ],
          vsn: 1.0
        })
        |> GenAI.with_message(%GenAI.Message.ToolResponse{
          tool_response: %{body: "Cats sleep up to 16 hours a day!"},
          tool_call_id: "call_zai_001"
        })

      {:ok, sut} = GenAI.run(thread)
      choice = sut.choices |> hd()
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content =~ "cats"
      assert choice.finish_reason == :stop
    end

    @tag :live
    @tag :advanced
    @tag provider: :zai
    @tag thread: :session
    test "Advanced Context run - vnext session" do
      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.ZAI.Models.glm_4_5_air())
        |> GenAI.with_setting(:temperature, 0.7)
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
      assert response.message.content =~ "Stanley Kubrick"
    end
  end
end
