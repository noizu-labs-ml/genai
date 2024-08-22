defmodule GenAI.Provider.AnthropicTest do
  use ExUnit.Case
  import GenAI.Test.Support.Common
  @moduletag provider: :anthropic

  def priv() do
    :code.priv_dir(:genai) |> List.to_string()
  end


  describe "Anthropic Provider" do
    test "chat - with function calls" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"msg_01XxRbEi4tvwxGZwPhMGBWU6\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"text\",\"text\":\"Okay, here is a tool call to generate a random fact about cats:\\n\\n<function_calls>\\n  <invoke>\\n    <tool_name>random_fact</tool_name>\\n    <parameters>{\\\"subject\\\": \\\"Cats\\\"}</parameters>\\n  </invoke>\\n</function_calls>\"}],\"model\":\"claude-3-opus-20240229\",\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":176,\"output_tokens\":71}}",
            headers: [],
            trailers: []
          }
        }
      end)

      {:ok, response} = GenAI.Provider.Anthropic.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
        ],
        [random_fact_tool()],
        [model: "claude-3-opus-20240229"]
      )
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.__struct__ == GenAI.Message.ToolCall
      [fc] = choice.message.tool_calls
      assert fc.function.name == "random_fact"
      assert fc.function.arguments[:subject] == "Cats"
    end


    test "chat - with function call response" do

      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"msg_01PZpcFJeqTEpPjP5XfmrMnM\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"text\",\"text\":\"Here is a random fact about cats, generated using the random_fact tool:\\n\\nCats have 230 bones, while humans only have 206.\\n\\nIsn't that interesting? Even though cats are much smaller than humans, they actually have more bones in their bodies. This is because cats have more vertebrae in their spines which allows them to be more flexible. Their flexible spine is one of the things that makes cats such agile climbers and jumpers.\\n\\nLet me know if you would like me to generate any other random cat facts using the tool!\"}],\"model\":\"claude-3-opus-20240229\",\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":339,\"output_tokens\":120}}",
            headers: [],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.Anthropic.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
          %GenAI.Message.ToolCall{
            role: :assistant,
            content: "Okay, here is a tool call to generate a random fact about cats:\n\n",
            tool_calls: [
              %{
                function: %{name: "random_fact", arguments: %{:subject => "Cats"}},
                id: "call_euQN3UTzL8HNn3jc2TzFnz",
                type: "function"
              }
            ],
            vsn: 1.0
          },
          %GenAI.Message.ToolResponse{
            response: %{
              body: "Cats have 230 bones, while humans only have 206"
            },
            tool_call_id: "call_euQN3UTzL8HNn3jc2TzFnz"
          }
        ],
        [random_fact_tool()],
        [model: "claude-3-opus-20240229"]
      )
      #IO.inspect(response, limit: :infinity, printable_limit: :infinity)
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.__struct__ == GenAI.Message
      assert choice.message.content == "Here is a random fact about cats, generated using the random_fact tool:\n\nCats have 230 bones, while humans only have 206.\n\nIsn't that interesting? Even though cats are much smaller than humans, they actually have more bones in their bodies. This is because cats have more vertebrae in their spines which allows them to be more flexible. Their flexible spine is one of the things that makes cats such agile climbers and jumpers.\n\nLet me know if you would like me to generate any other random cat facts using the tool!"
    end

    test "chat" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok, %Finch.Response{
          status: 200,
          body: "{\"id\":\"msg_01B1hbPMtpwoSFQfVGN5q2WV\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"text\",\"text\":\"Hello!\"}],\"model\":\"claude-3-opus-20240229\",\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":10,\"output_tokens\":5}}",
          headers: [],
          trailers: []
        }
        }
      end)

      {:ok, response} = GenAI.Provider.Anthropic.chat(
        [
          %GenAI.Message{role: :user, content: "Say Hello."},
        ],
        nil,
        [model: "claude-3-opus-20240229"]
      )
      assert response.provider == GenAI.Provider.Anthropic
      assert response.model == "claude-3-opus-20240229"
      assert response.seed == nil
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Hello!"
      assert choice.finish_reason == :stop
    end

    @tag :vision
    @tag :advanced
    test "Vision Test" do
      Mimic.expect(Finch, :request, fn(request, _, _) ->
        assert request.body =~ "{\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Describe this image\"},{\"type\":\"image\",\"source\":{\"data\":\"/9j/6zMMSlATAAAAAAAAADMC"
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"msg_01H7uiwqdf2SNyP1N5EfnpGV\",\"type\":\"message\",\"role\":\"assistant\",\"model\":\"claude-3-5-sonnet-20240620\",\"content\":[{\"type\":\"text\",\"text\":\"This image shows a cute, cartoon-style illustration of a small cat sitting in a floral setting. The cat is predominantly white with orange patches, has large, expressive eyes, and a small pink nose. It's sitting on a patch of green grass surrounded by colorful flowers in shades of blue, red, and yellow. \\n\\nThe background is a soft mint green circle, giving the impression of a peaceful spring or summer day. There are three butterflies fluttering around the cat - two pink ones and a white silhouette. The overall style is very kawaii or cute, with simplified shapes and a cheerful color palette.\\n\\nThe cat's expression is sweet and content, with closed eyes and a small smile, adding to the overall warm and friendly atmosphere of the illustration. This type of image would be popular for children's books, greeting cards, or as a cute digital sticker or emoji.\"}],\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":1383,\"output_tokens\":190}}",
            headers: [],
            trailers: []
          }}
      end)

      thread = GenAI.chat(:standard)
               |> GenAI.with_model(GenAI.Provider.Anthropic.Models.claude_sonnet_3_5())
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_message(
                    %GenAI.Message{
                      role: :user,
                      content: [
                        "Describe this image",
                        GenAI.Message.image(priv() <> "/media/kitten.jpeg")
                      ]
                    })
      {:ok, sut} = GenAI.run(thread)
      response = sut.choices |> hd()
      assert response.message.content =~ "This image shows a cute, cartoon-style illustration of a small cat"
    end

  end

end
