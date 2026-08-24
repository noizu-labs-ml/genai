defmodule GenAI.Provider.OpenRouterTest do
  use ExUnit.Case

  @moduletag provider: :openrouter

  setup do
    prev = Application.get_env(:genai, :openrouter, [])

    Application.put_env(
      :genai,
      :openrouter,
      prev
      |> Keyword.put(:api_key, "test-openrouter-key")
      |> Keyword.put(:http_referer, "https://example.test")
      |> Keyword.put(:app_title, "GenAI Test")
    )

    on_exit(fn -> Application.put_env(:genai, :openrouter, prev) end)
    :ok
  end

  describe "OpenRouter Provider" do
    test "models" do
      Mimic.expect(Finch, :request, fn request, _, _ ->
        assert request.host == "openrouter.ai"
        assert request.path == "/api/v1/models"

        auth =
          Enum.find_value(request.headers, fn
            {"Authorization", value} -> value
            {"authorization", value} -> value
            _ -> nil
          end)

        assert auth == "Bearer test-openrouter-key"

        referer =
          Enum.find_value(request.headers, fn
            {"HTTP-Referer", value} -> value
            _ -> nil
          end)

        assert referer == "https://example.test"

        {:ok,
         %Finch.Response{
           status: 200,
           body: ~s({
  "object": "list",
  "data": [
    {"id": "openai/gpt-4o", "object": "model", "owned_by": "openai"},
    {"id": "anthropic/claude-sonnet-4", "object": "model", "owned_by": "anthropic"}
  ]
}),
           headers: [{"content-type", "application/json"}],
           trailers: []
         }}
      end)

      {:ok, models} = GenAI.Provider.OpenRouter.models()
      sut = Enum.find(models, &(&1.model == "openai/gpt-4o"))
      assert sut
      assert sut.provider == GenAI.Provider.OpenRouter
    end

    test "chat - basic completion" do
      Mimic.expect(Finch, :request, fn request, _, _ ->
        assert request.host == "openrouter.ai"
        assert request.path == "/api/v1/chat/completions"

        {:ok,
         %Finch.Response{
           status: 200,
           body: ~s({
  "id": "gen-or-abc123",
  "object": "chat.completion",
  "created": 1754000000,
  "model": "openai/gpt-4o",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello from OpenRouter."
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 8,
    "completion_tokens": 5,
    "total_tokens": 13
  }
}),
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.OpenRouter.Models.gpt_4o())
        |> GenAI.with_setting(:temperature, 0.2)
        |> GenAI.with_message(%GenAI.Message{role: :user, content: "Say Hello."})

      {:ok, sut} = GenAI.run(thread)
      choice = sut.choices |> hd()
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Hello from OpenRouter."
      assert choice.finish_reason == :stop
    end
  end
end
