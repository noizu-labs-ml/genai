defmodule GenAI.Provider.OpenAITest do
  use ExUnit.Case
  import GenAI.Test.Support.Common
  @moduletag provider: :open_ai

  def priv() do
    :code.priv_dir(:genai) |> List.to_string()
  end

  describe "OpenAI Provider" do

    @tag :wip
    test "Model And Model Database Binding" do
        {:ok, models} = GenAI.Provider.OpenAI.Models.list()
        # IO.inspect(models, label: Models, limit: :infinity)
    end

    @tag :models
    test "models" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"object\": \"list\",\n  \"data\": [\n    {\n      \"id\": \"gpt-3.5-turbo-16k\",\n      \"object\": \"model\",\n      \"created\": 1683758102,\n      \"owned_by\": \"openai-internal\"\n    },\n    {\n      \"id\": \"gpt-3.5-turbo-1106\",\n      \"object\": \"model\",\n      \"created\": 1698959748,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"dall-e-3\",\n      \"object\": \"model\",\n      \"created\": 1698785189,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-3.5-turbo-16k-0613\",\n      \"object\": \"model\",\n      \"created\": 1685474247,\n      \"owned_by\": \"openai\"\n    },\n    {\n      \"id\": \"dall-e-2\",\n      \"object\": \"model\",\n      \"created\": 1698798177,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"text-embedding-3-large\",\n      \"object\": \"model\",\n      \"created\": 1705953180,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"whisper-1\",\n      \"object\": \"model\",\n      \"created\": 1677532384,\n      \"owned_by\": \"openai-internal\"\n    },\n    {\n      \"id\": \"tts-1-hd-1106\",\n      \"object\": \"model\",\n      \"created\": 1699053533,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"tts-1-hd\",\n      \"object\": \"model\",\n      \"created\": 1699046015,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-3.5-turbo\",\n      \"object\": \"model\",\n      \"created\": 1677610602,\n      \"owned_by\": \"openai\"\n    },\n    {\n      \"id\": \"gpt-3.5-turbo-0125\",\n      \"object\": \"model\",\n      \"created\": 1706048358,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-4-0613\",\n      \"object\": \"model\",\n      \"created\": 1686588896,\n      \"owned_by\": \"openai\"\n    },\n    {\n      \"id\": \"gpt-3.5-turbo-0301\",\n      \"object\": \"model\",\n      \"created\": 1677649963,\n      \"owned_by\": \"openai\"\n    },\n    {\n      \"id\": \"gpt-3.5-turbo-0613\",\n      \"object\": \"model\",\n      \"created\": 1686587434,\n      \"owned_by\": \"openai\"\n    },\n    {\n      \"id\": \"gpt-3.5-turbo-instruct-0914\",\n      \"object\": \"model\",\n      \"created\": 1694122472,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-4\",\n      \"object\": \"model\",\n      \"created\": 1687882411,\n      \"owned_by\": \"openai\"\n    },\n    {\n      \"id\": \"tts-1\",\n      \"object\": \"model\",\n      \"created\": 1681940951,\n      \"owned_by\": \"openai-internal\"\n    },\n    {\n      \"id\": \"davinci-002\",\n      \"object\": \"model\",\n      \"created\": 1692634301,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-3.5-turbo-instruct\",\n      \"object\": \"model\",\n      \"created\": 1692901427,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"babbage-002\",\n      \"object\": \"model\",\n      \"created\": 1692634615,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-4-1106-preview\",\n      \"object\": \"model\",\n      \"created\": 1698957206,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-4-vision-preview\",\n      \"object\": \"model\",\n      \"created\": 1698894917,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"tts-1-1106\",\n      \"object\": \"model\",\n      \"created\": 1699053241,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-4-0125-preview\",\n      \"object\": \"model\",\n      \"created\": 1706037612,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"gpt-4-turbo-preview\",\n      \"object\": \"model\",\n      \"created\": 1706037777,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"text-embedding-ada-002\",\n      \"object\": \"model\",\n      \"created\": 1671217299,\n      \"owned_by\": \"openai-internal\"\n    },\n    {\n      \"id\": \"text-embedding-3-small\",\n      \"object\": \"model\",\n      \"created\": 1705948997,\n      \"owned_by\": \"system\"\n    },\n    {\n      \"id\": \"ft:gpt-3.5-turbo-1106:noizu-labs::8MT7kKko\",\n      \"object\": \"model\",\n      \"created\": 1700365860,\n      \"owned_by\": \"noizu-labs\"\n    }\n  ]\n}\n",
            headers: [],
            trailers: []
          }
        }
      end
      )
      {:ok, [h|_]} = GenAI.Provider.OpenAI.models()
      assert h.model == "gpt-3.5-turbo-16k"
    end


    @tag :tool_usage
    test "chat - with function calls" do

      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"id\": \"chatcmpl-93UsW2K75QeYQJWuImeSI3PZ7TXfx\",\n  \"object\": \"chat.completion\",\n  \"created\": 1710620708,\n  \"model\": \"gpt-3.5-turbo-0125\",\n  \"choices\": [\n    {\n      \"index\": 0,\n      \"message\": {\n        \"role\": \"assistant\",\n        \"content\": null,\n        \"tool_calls\": [\n          {\n            \"id\": \"call_pSe98iKMXYxjNriBuEqQFltC\",\n            \"type\": \"function\",\n            \"function\": {\n              \"name\": \"random_fact\",\n              \"arguments\": \"{\\\"subject\\\":\\\"cats\\\"}\"\n            }\n          }\n        ]\n      },\n      \"logprobs\": null,\n      \"finish_reason\": \"tool_calls\"\n    }\n  ],\n  \"usage\": {\n    \"prompt_tokens\": 70,\n    \"completion_tokens\": 14,\n    \"total_tokens\": 84\n  },\n  \"system_fingerprint\": \"fp_4f2ebda25a\"\n}\n",
            headers: [],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.OpenAI.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
        ],
        [random_fact_tool()],
        [model: "gpt-3.5-turbo"]
      )
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.__struct__ == GenAI.Message.ToolCall
      [fc] = choice.message.tool_calls
      assert fc.function.name == "random_fact"
      assert fc.function.arguments[:subject] == "cats"
    end



    @tag :tool_usage
    test "chat - with function call response" do

      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"id\": \"chatcmpl-93VRTHCMIdPNud23DjX3GHs2T2sV8\",\n  \"object\": \"chat.completion\",\n  \"created\": 1710622875,\n  \"model\": \"gpt-3.5-turbo-0125\",\n  \"choices\": [\n    {\n      \"index\": 0,\n      \"message\": {\n        \"role\": \"assistant\",\n        \"content\": \"Here's a random fact about cats: \\\"Cats are awesome, now there's a cat fact!\\\"\"\n      },\n      \"logprobs\": null,\n      \"finish_reason\": \"stop\"\n    }\n  ],\n  \"usage\": {\n    \"prompt_tokens\": 108,\n    \"completion_tokens\": 22,\n    \"total_tokens\": 130\n  },\n  \"system_fingerprint\": \"fp_4f2ebda25a\"\n}\n",
            headers: [],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.OpenAI.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
          %GenAI.Message.ToolCall{
            role: :assistant,
            content: nil,
            tool_calls: [
              %{
                function: %{name: "random_fact", arguments: %{:subject => "cats"}},
                id: "call_pSe98iKMXYxjNriBuEqQFltC",
                type: "function"
              }
            ],
            vsn: 1.0
          },
          %GenAI.Message.ToolResponse{
            response: %{
              body: "Cats are awesome, now there's a cat fact!"
            },
            tool_call_id: "call_pSe98iKMXYxjNriBuEqQFltC"
          }
        ],
        [random_fact_tool()],
        [model: "gpt-3.5-turbo"]
      )
      assert response.provider == GenAI.Provider.OpenAI
      assert response.model == "gpt-3.5-turbo-0125"
      assert response.seed == nil
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Here's a random fact about cats: \"Cats are awesome, now there's a cat fact!\""
      assert choice.finish_reason == :stop
    end


    test "chat" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"id\": \"chatcmpl-93OJTB9hxpGLsin0QnJjYiZmdJjUR\",\n  \"object\": \"chat.completion\",\n  \"created\": 1710595471,\n  \"model\": \"gpt-3.5-turbo-0125\",\n  \"choices\": [\n    {\n      \"index\": 0,\n      \"message\": {\n        \"role\": \"assistant\",\n        \"content\": \"Hello! How can I assist you today?\"\n      },\n      \"logprobs\": null,\n      \"finish_reason\": \"stop\"\n    }\n  ],\n  \"usage\": {\n    \"prompt_tokens\": 10,\n    \"completion_tokens\": 9,\n    \"total_tokens\": 19\n  },\n  \"system_fingerprint\": \"fp_4f2ebda25a\"\n}\n",
            headers: [],
            trailers: []
          }
        }
      end)


      {:ok, response} = GenAI.Provider.OpenAI.chat(
        [
          %GenAI.Message{role: :user, content: "Say Hello."},
        ],
        nil,
        [model: "gpt-3.5-turbo"]
      )

      assert response.provider == GenAI.Provider.OpenAI
      assert response.model == "gpt-3.5-turbo-0125"
      assert response.seed == nil
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Hello! How can I assist you today?"
      assert choice.finish_reason == :stop
    end

    @tag :vision
    @tag :advanced
    test "Vision Test" do
      Mimic.expect(Finch, :request, fn(request, _, _) ->
        assert request.body =~ "{\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Describe this image\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"data:image/jpeg;base64,/9j/4QBORXhpZgAATU0AKg"
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"id\": \"chatcmpl-9x9CKRSPYms2YazF2qpf0eZoJd8mE\",\n  \"object\": \"chat.completion\",\n  \"created\": 1723883736,\n  \"model\": \"gpt-4o-mini-2024-07-18\",\n  \"choices\": [\n    {\n      \"index\": 0,\n      \"message\": {\n        \"role\": \"assistant\",\n        \"content\": \"The image features an adorable cartoon-style cat with large, expressive eyes and a playful expression. The cat is predominantly white, with a few orange spots on its head. It is sitting on a patch of green grass surrounded by colorful flowers, including blue and pink blooms. There are also butterflies fluttering around the cat, adding to the whimsical and cheerful atmosphere of the scene. The background has a soft green hue, enhancing the overall cute and friendly vibe.\",\n        \"refusal\": null\n      },\n      \"logprobs\": null,\n      \"finish_reason\": \"stop\"\n    }\n  ],\n  \"usage\": {\n    \"prompt_tokens\": 25511,\n    \"completion_tokens\": 90,\n    \"total_tokens\": 25601\n  },\n  \"system_fingerprint\": \"fp_507c9469a1\"\n}\n",
            headers: [],
            trailers: []
          }}
      end)

      thread = GenAI.chat(:standard)
               |> GenAI.with_model(GenAI.Provider.OpenAI.Models.gpt_4o_mini())
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
      assert response.message.content =~ "The image features an adorable cartoon-style cat"
    end

  end

end
