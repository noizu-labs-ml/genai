defmodule GenAI.Provider.AnthropicTest do
  use ExUnit.Case
  import GenAI.Test.Support.Common
  @moduletag provider: :anthropic

  def priv() do
    :code.priv_dir(:genai) |> List.to_string()
  end

  describe "Anthropic Provider" do
    test "chat - with function calls" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: """
           {
             \"id\": \"msg_01Aq9w938a90dw8q\",
             \"model\": \"claude-3-7-sonnet-20250219\",
             \"stop_reason\": \"tool_use\",
             \"role\": \"assistant\",
             \"content\": [
               {
                 \"type\": \"text\",
                 \"text\": \"<thinking>I need to use the random_fact, and the user wants SF, which is likely San Francisco, CA.</thinking>\"
               },
               {
                 \"type\": \"tool_use\",
                 \"id\": \"toolu_01A09q90qw90lq917835lq9\",
                 \"name\": \"random_fact\",
                 \"input\": {\"subject\": \"Cats\"}
               }
             ]
           }
           """,
           headers: [],
           trailers: []
         }}
      end)

      {:ok, response} =
        GenAI.Provider.Anthropic.chat(
          [
            %GenAI.Message{
              role: :user,
              content: "Tell me a random fact about cats using a tool call."
            }
          ],
          [random_fact_tool()],
          model: "claude-3-opus-20240229"
        )

      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.__struct__ == GenAI.Message.ToolUsage
      [_, fc] = choice.message.content
      assert fc.tool_name == "random_fact"
      assert fc.arguments[:subject] == "Cats"
    end

    test "chat - with function call response" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             "{\"id\":\"msg_01PZpcFJeqTEpPjP5XfmrMnM\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"text\",\"text\":\"Here is a random fact about cats, generated using the random_fact tool:\\n\\nCats have 230 bones, while humans only have 206.\\n\\nIsn't that interesting? Even though cats are much smaller than humans, they actually have more bones in their bodies. This is because cats have more vertebrae in their spines which allows them to be more flexible. Their flexible spine is one of the things that makes cats such agile climbers and jumpers.\\n\\nLet me know if you would like me to generate any other random cat facts using the tool!\"}],\"model\":\"claude-3-opus-20240229\",\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":339,\"output_tokens\":120}}",
           headers: [],
           trailers: []
         }}
      end)

      {:ok, response} =
        GenAI.Provider.Anthropic.chat(
          [
            %GenAI.Message{
              role: :user,
              content: "Tell me a random fact about cats using a tool call."
            },
            %GenAI.Message.ToolUsage{
              role: :assistant,
              content: "Okay, here is a tool call to generate a random fact about cats:\n\n",
              tool_calls: [
                %GenAI.Message.ToolCall{
                  id: "call_euQN3UTzL8HNn3jc2TzFnz",
                  tool_name: "random_fact",
                  arguments: %{:subject => "Cats"}
                }
              ],
              vsn: 1.0
            },
            %GenAI.Message.ToolResponse{
              tool_response: %{
                body: "Cats have 230 bones, while humans only have 206"
              },
              tool_call_id: "call_euQN3UTzL8HNn3jc2TzFnz"
            }
          ],
          [random_fact_tool()],
          model: "claude-3-opus-20240229"
        )

      # IO.inspect(response, limit: :infinity, printable_limit: :infinity)
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.__struct__ == GenAI.Message

      expected_content = [
        %GenAI.Message.Content.TextContent{
          system: false,
          type: :response,
          text:
            "Here is a random fact about cats, generated using the random_fact tool:\n\nCats have 230 bones, while humans only have 206.\n\nIsn't that interesting? Even though cats are much smaller than humans, they actually have more bones in their bodies. This is because cats have more vertebrae in their spines which allows them to be more flexible. Their flexible spine is one of the things that makes cats such agile climbers and jumpers.\n\nLet me know if you would like me to generate any other random cat facts using the tool!",
          citations: nil,
          vsn: 1.0
        }
      ]

      assert choice.message.content == expected_content
    end

    test "chat" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             "{\"id\":\"msg_01B1hbPMtpwoSFQfVGN5q2WV\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"text\",\"text\":\"Hello!\"}],\"model\":\"claude-3-opus-20240229\",\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":10,\"output_tokens\":5}}",
           headers: [],
           trailers: []
         }}
      end)

      {:ok, response} =
        GenAI.Provider.Anthropic.chat(
          [
            %GenAI.Message{role: :user, content: "Say Hello."}
          ],
          nil,
          model: "claude-3-opus-20240229"
        )

      assert response.provider == GenAI.Provider.Anthropic
      assert response.model == "claude-3-opus-20240229"
      assert response.seed == nil
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant

      assert choice.message.content == [
               %GenAI.Message.Content.TextContent{
                 system: false,
                 type: :response,
                 text: "Hello!",
                 citations: nil,
                 vsn: 1.0
               }
             ]

      assert choice.finish_reason == :stop
    end

    @tag :vision
    @tag :advanced
    test "Vision Test" do
      Mimic.expect(Finch, :request, fn request, _, _ ->
        assert request.body =~
                 "{\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Describe this image\"},{\"type\":\"image\",\"source\":{\"data\":\"/9j/4QBORXhpZgAATU0AKgAAAAgAAwEaAAUAAAABAAAAMgEbAAUAAAABAAAAOgEoAAMAAAABAAIAAAAAAAAADqYAAAAnEAAOpgAAACcQAAAAAP/tAEBQaG90b3Nob"

        {:ok,
         %Finch.Response{
           status: 200,
           body:
             "{\"id\":\"msg_01H7uiwqdf2SNyP1N5EfnpGV\",\"type\":\"message\",\"role\":\"assistant\",\"model\":\"claude-3-5-sonnet-20240620\",\"content\":[{\"type\":\"text\",\"text\":\"This image shows a cute, cartoon-style illustration of a small cat sitting in a floral setting. The cat is predominantly white with orange patches, has large, expressive eyes, and a small pink nose. It's sitting on a patch of green grass surrounded by colorful flowers in shades of blue, red, and yellow. \\n\\nThe background is a soft mint green circle, giving the impression of a peaceful spring or summer day. There are three butterflies fluttering around the cat - two pink ones and a white silhouette. The overall style is very kawaii or cute, with simplified shapes and a cheerful color palette.\\n\\nThe cat's expression is sweet and content, with closed eyes and a small smile, adding to the overall warm and friendly atmosphere of the illustration. This type of image would be popular for children's books, greeting cards, or as a cute digital sticker or emoji.\"}],\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":1383,\"output_tokens\":190}}",
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:standard)
        |> GenAI.with_model(GenAI.Provider.Anthropic.Models.claude_sonnet_3_5())
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_message(%GenAI.Message{
          role: :user,
          content: [
            "Describe this image",
            GenAI.Message.image(priv() <> "/media/kitten.jpeg")
          ]
        })

      {:ok, sut} = GenAI.run(thread)
      response = sut.choices |> hd()

      [text_content = %GenAI.Message.Content.TextContent{}] = response.message.content

      assert text_content.text =~
               "This image shows a cute, cartoon-style illustration of a small cat"
    end

    @tag :vision
    @tag :advanced
    test "Vision Test - vnext session" do
      Mimic.expect(Finch, :request, fn request, _, _ ->
        assert request.body =~
                 "{\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Describe this image\"},{\"type\":\"image\",\"source\":{\"data\":\"/9j/4QBORXhpZgAATU0AKgAAAAgAAwEaAAUAAAABAAAAMgEbAAUAAAABAAAAOgEoAAMAAAABAAIAAAAAAAAADqYAAAAnEAAOpgAAACcQAAAAAP/tAEBQaG90b3Nob"

        {:ok,
         %Finch.Response{
           status: 200,
           body:
             "{\"id\":\"msg_01H7uiwqdf2SNyP1N5EfnpGV\",\"type\":\"message\",\"role\":\"assistant\",\"model\":\"claude-3-5-sonnet-20240620\",\"content\":[{\"type\":\"text\",\"text\":\"This image shows a cute, cartoon-style illustration of a small cat sitting in a floral setting. The cat is predominantly white with orange patches, has large, expressive eyes, and a small pink nose. It's sitting on a patch of green grass surrounded by colorful flowers in shades of blue, red, and yellow. \\n\\nThe background is a soft mint green circle, giving the impression of a peaceful spring or summer day. There are three butterflies fluttering around the cat - two pink ones and a white silhouette. The overall style is very kawaii or cute, with simplified shapes and a cheerful color palette.\\n\\nThe cat's expression is sweet and content, with closed eyes and a small smile, adding to the overall warm and friendly atmosphere of the illustration. This type of image would be popular for children's books, greeting cards, or as a cute digital sticker or emoji.\"}],\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":1383,\"output_tokens\":190}}",
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(GenAI.Provider.Anthropic.Models.claude_sonnet_3_5())
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_message(%GenAI.Message{
          role: :user,
          content: [
            "Describe this image",
            GenAI.Message.image(priv() <> "/media/kitten.jpeg")
          ]
        })

      {:ok, sut} = GenAI.run(thread)
      response = sut.choices |> hd()
      [text_content = %GenAI.Message.Content.TextContent{}] = response.message.content

      assert text_content.text =~
               "This image shows a cute, cartoon-style illustration of a small cat"
    end
  end

  describe "prompt caching - usage" do
    test "usage includes cache read/creation tokens" do
      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             ~s({"id":"msg_01CACHE","type":"message","role":"assistant","model":"claude-3-5-sonnet-20241022","content":[{"type":"text","text":"Hi!"}],"stop_reason":"end_turn","stop_sequence":null,"usage":{"input_tokens":2095,"output_tokens":503,"cache_creation_input_tokens":2095,"cache_read_input_tokens":0}}),
           headers: [],
           trailers: []
         }}
      end)

      {:ok, response} =
        GenAI.Provider.Anthropic.chat(
          [%GenAI.Message{role: :user, content: "Hello"}],
          [],
          model: "claude-3-5-sonnet-20241022"
        )

      assert response.usage.prompt_tokens == 2095
      assert response.usage.completion_tokens == 503
      assert response.usage.cache_creation_input_tokens == 2095
      assert response.usage.cache_read_input_tokens == 0
    end
  end

  describe "prompt caching - request side" do
    def caching_model() do
      %GenAI.Model{
        model: "claude-3-5-sonnet-20241022",
        provider: GenAI.Provider.Anthropic,
        encoder: GenAI.Provider.Anthropic.Encoder
      }
    end

    def caching_messages() do
      [
        %{role: :user, content: [%{type: :text, text: "hello"}]}
      ]
    end

    test "cache_control setting wraps system prompt as ephemeral breakpoint" do
      settings = %{
        settings: [system_prompt: "You are helpful.", cache_control: :ephemeral],
        model_settings: [],
        provider_settings: [],
        config_settings: []
      }

      {:ok, {body, _session}} =
        GenAI.Provider.Anthropic.Encoder.request_body(
          caching_model(),
          caching_messages(),
          [],
          settings,
          nil,
          nil,
          nil
        )

      assert body.system == [
               %{type: "text", text: "You are helpful.", cache_control: %{type: "ephemeral"}}
             ]
    end

    test "no cache_control setting leaves system prompt untouched" do
      settings = %{
        settings: [system_prompt: "You are helpful."],
        model_settings: [],
        provider_settings: [],
        config_settings: []
      }

      {:ok, {body, _session}} =
        GenAI.Provider.Anthropic.Encoder.request_body(
          caching_model(),
          caching_messages(),
          [],
          settings,
          nil,
          nil,
          nil
        )

      assert body.system == "You are helpful."
    end

    test "more than 4 cache breakpoints are capped with warning" do
      blocks =
        for i <- 1..6, do: %{type: :text, text: "block #{i}", cache_control: %{type: "ephemeral"}}

      messages = [%{role: :user, content: blocks}]
      settings = %{settings: [], model_settings: [], provider_settings: [], config_settings: []}

      {:ok, {body, _session}} =
        GenAI.Provider.Anthropic.Encoder.request_body(
          caching_model(),
          messages,
          [],
          settings,
          nil,
          nil,
          nil
        )

      [user] = body.messages
      kept = Enum.count(user.content, &Map.has_key?(&1, :cache_control))
      assert kept == 4
      assert Enum.count(user.content) == 6
    end

    test "binary system prompt is left intact when only message blocks carry breakpoints" do
      blocks =
        for i <- 1..6, do: %{type: :text, text: "block #{i}", cache_control: %{type: "ephemeral"}}

      messages = [%{role: :user, content: blocks}]

      settings = %{
        settings: [system_prompt: "You are helpful."],
        model_settings: [],
        provider_settings: [],
        config_settings: []
      }

      {:ok, {body, _session}} =
        GenAI.Provider.Anthropic.Encoder.request_body(
          caching_model(),
          messages,
          [],
          settings,
          nil,
          nil,
          nil
        )

      assert body.system == "You are helpful."
    end

    test "no system prompt key is left untouched when cache_control is set" do
      settings = %{
        settings: [cache_control: :ephemeral],
        model_settings: [],
        provider_settings: [],
        config_settings: []
      }

      {:ok, {body, _session}} =
        GenAI.Provider.Anthropic.Encoder.request_body(
          caching_model(),
          [%{role: :user, content: [%{type: :text, text: "hi"}]}],
          [],
          settings,
          nil,
          nil,
          nil
        )

      refute Map.has_key?(body, :system)
    end

    test "TextContent with cache_control serializes an ephemeral breakpoint" do
      content = %GenAI.Message.Content.TextContent{text: "big context", cache_control: true}

      {block, _session} =
        GenAI.Provider.Anthropic.EncoderProtocolHelper.content(
          content,
          content,
          nil,
          nil,
          nil,
          nil
        )

      assert block.cache_control == %{type: "ephemeral"}
    end
  end
end
