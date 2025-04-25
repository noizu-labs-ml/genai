defmodule GenAI.Provider.GeminiTest do
  use ExUnit.Case
  import GenAI.Test.Support.Common
  @moduletag provider: :gemini


  def priv() do
    :code.priv_dir(:genai) |> List.to_string()
  end

  describe "Gemini Provider" do
    test "models" do

      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok, %Finch.Response{
          status: 200,
          body: "{\n  \"models\": [\n    {\n      \"name\": \"models/chat-bison-001\",\n      \"version\": \"001\",\n      \"displayName\": \"PaLM 2 Chat (Legacy)\",\n      \"description\": \"A legacy text-only model optimized for chat conversations\",\n      \"inputTokenLimit\": 4096,\n      \"outputTokenLimit\": 1024,\n      \"supportedGenerationMethods\": [\n        \"generateMessage\",\n        \"countMessageTokens\"\n      ],\n      \"temperature\": 0.25,\n      \"topP\": 0.95,\n      \"topK\": 40\n    },\n    {\n      \"name\": \"models/text-bison-001\",\n      \"version\": \"001\",\n      \"displayName\": \"PaLM 2 (Legacy)\",\n      \"description\": \"A legacy model that understands text and generates text as an output\",\n      \"inputTokenLimit\": 8196,\n      \"outputTokenLimit\": 1024,\n      \"supportedGenerationMethods\": [\n        \"generateText\",\n        \"countTextTokens\",\n        \"createTunedTextModel\"\n      ],\n      \"temperature\": 0.7,\n      \"topP\": 0.95,\n      \"topK\": 40\n    },\n    {\n      \"name\": \"models/embedding-gecko-001\",\n      \"version\": \"001\",\n      \"displayName\": \"Embedding Gecko\",\n      \"description\": \"Obtain a distributed representation of a text.\",\n      \"inputTokenLimit\": 1024,\n      \"outputTokenLimit\": 1,\n      \"supportedGenerationMethods\": [\n        \"embedText\",\n        \"countTextTokens\"\n      ]\n    },\n    {\n      \"name\": \"models/gemini-1.0-pro\",\n      \"version\": \"001\",\n      \"displayName\": \"Gemini 1.0 Pro\",\n      \"description\": \"The best model for scaling across a wide range of tasks\",\n      \"inputTokenLimit\": 30720,\n      \"outputTokenLimit\": 2048,\n      \"supportedGenerationMethods\": [\n        \"generateContent\",\n        \"countTokens\"\n      ],\n      \"temperature\": 0.9,\n      \"topP\": 1,\n      \"topK\": 1\n    },\n    {\n      \"name\": \"models/gemini-1.0-pro-001\",\n      \"version\": \"001\",\n      \"displayName\": \"Gemini 1.0 Pro 001 (Tuning)\",\n      \"description\": \"The best model for scaling across a wide range of tasks. This is a stable model that supports tuning.\",\n      \"inputTokenLimit\": 30720,\n      \"outputTokenLimit\": 2048,\n      \"supportedGenerationMethods\": [\n        \"generateContent\",\n        \"countTokens\",\n        \"createTunedModel\"\n      ],\n      \"temperature\": 0.9,\n      \"topP\": 1,\n      \"topK\": 1\n    },\n    {\n      \"name\": \"models/gemini-1.0-pro-latest\",\n      \"version\": \"001\",\n      \"displayName\": \"Gemini 1.0 Pro Latest\",\n      \"description\": \"The best model for scaling across a wide range of tasks. This is the latest model.\",\n      \"inputTokenLimit\": 30720,\n      \"outputTokenLimit\": 2048,\n      \"supportedGenerationMethods\": [\n        \"generateContent\",\n        \"countTokens\"\n      ],\n      \"temperature\": 0.9,\n      \"topP\": 1,\n      \"topK\": 1\n    },\n    {\n      \"name\": \"models/gemini-1.0-pro-vision-latest\",\n      \"version\": \"001\",\n      \"displayName\": \"Gemini 1.0 Pro Vision\",\n      \"description\": \"The best image understanding model to handle a broad range of applications\",\n      \"inputTokenLimit\": 12288,\n      \"outputTokenLimit\": 4096,\n      \"supportedGenerationMethods\": [\n        \"generateContent\",\n        \"countTokens\"\n      ],\n      \"temperature\": 0.4,\n      \"topP\": 1,\n      \"topK\": 32\n    },\n    {\n      \"name\": \"models/gemini-pro\",\n      \"version\": \"001\",\n      \"displayName\": \"Gemini 1.0 Pro\",\n      \"description\": \"The best model for scaling across a wide range of tasks\",\n      \"inputTokenLimit\": 30720,\n      \"outputTokenLimit\": 2048,\n      \"supportedGenerationMethods\": [\n        \"generateContent\",\n        \"countTokens\"\n      ],\n      \"temperature\": 0.9,\n      \"topP\": 1,\n      \"topK\": 1\n    },\n    {\n      \"name\": \"models/gemini-pro-vision\",\n      \"version\": \"001\",\n      \"displayName\": \"Gemini 1.0 Pro Vision\",\n      \"description\": \"The best image understanding model to handle a broad range of applications\",\n      \"inputTokenLimit\": 12288,\n      \"outputTokenLimit\": 4096,\n      \"supportedGenerationMethods\": [\n        \"generateContent\",\n        \"countTokens\"\n      ],\n      \"temperature\": 0.4,\n      \"topP\": 1,\n      \"topK\": 32\n    },\n    {\n      \"name\": \"models/embedding-001\",\n      \"version\": \"001\",\n      \"displayName\": \"Embedding 001\",\n      \"description\": \"Obtain a distributed representation of a text.\",\n      \"inputTokenLimit\": 2048,\n      \"outputTokenLimit\": 1,\n      \"supportedGenerationMethods\": [\n        \"embedContent\"\n      ]\n    },\n    {\n      \"name\": \"models/aqa\",\n      \"version\": \"001\",\n      \"displayName\": \"Model that performs Attributed Question Answering.\",\n      \"description\": \"Model trained to return answers to questions that are grounded in provided sources, along with estimating answerable probability.\",\n      \"inputTokenLimit\": 7168,\n      \"outputTokenLimit\": 1024,\n      \"supportedGenerationMethods\": [\n        \"generateAnswer\"\n      ],\n      \"temperature\": 0.2,\n      \"topP\": 1,\n      \"topK\": 40\n    }\n  ]\n}\n",
          headers: [
          ],
          trailers: []
        }
        }
      end)

      {:ok, [h|_]} = GenAI.Provider.Gemini.models()
      assert h.model == "models/chat-bison-001"
    end

    test "chat" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"candidates\": [\n    {\n      \"content\": {\n        \"parts\": [\n          {\n            \"text\": \"Hello there!\"\n          }\n        ],\n        \"role\": \"model\"\n      },\n      \"finishReason\": \"STOP\",\n      \"index\": 0,\n      \"safetyRatings\": [\n        {\n          \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HARASSMENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        }\n      ]\n    }\n  ],\n  \"promptFeedback\": {\n    \"safetyRatings\": [\n      {\n        \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_HARASSMENT\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n        \"probability\": \"NEGLIGIBLE\"\n      }\n    ]\n  }\n}\n",
            headers: [],
            trailers: []
          }
        }
      end)

      {:ok, response} = GenAI.Provider.Gemini.chat(
        [
          %GenAI.Message{role: :user, content: "Say Hello."},
        ],
        nil,
        [model: "gemini-pro"]
      )
      assert response.provider == GenAI.Provider.Gemini
      assert response.model == "gemini-pro"
      assert response.seed == nil
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Hello there!"
      assert choice.finish_reason == :stop
    end


    test "chat - with function calls" do

      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"candidates\": [\n    {\n      \"content\": {\n        \"parts\": [\n          {\n            \"functionCall\": {\n              \"name\": \"random_fact\",\n              \"args\": {\n
      \"subject\": \"Cats\"\n              }\n            }\n          }\n        ],\n        \"role\": \"model\"\n      },\n      \"finishReason\": \"STOP\",\n      \"index\": 0,\n      \"safetyRatings\": [\n        {\n          \"category\": \"HARM_CATEGORY_HARASSMENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n          \"probability\": \"NEGLIGIBLE\"\n        }\n      ]\n    }\n  ],\n  \"promptFeedback\": {\n    \"safetyRatings\": [\n      {\n        \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_HARASSMENT\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n        \"probability\": \"NEGLIGIBLE\"\n      }\n    ]\n  }\n}\n",
            headers: [],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.Gemini.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
        ],
        [random_fact_tool()],
        [model: "gemini-pro"]
      )
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.__struct__ == GenAI.Message.ToolUsage
      [fc] = choice.message.tool_calls
      assert fc.function.name == "random_fact"
      assert fc.function.arguments[:subject] == "Cats"
    end


    test "chat - with function call response" do

      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"candidates\": [\n    {\n      \"content\": {\n        \"parts\": [\n          {\n            \"text\": \"Cats have 230 bones, while humans only have 206\"\n          }\n        ],\n        \"role\": \"model\"\n      },\n      \"finishReason\": \"STOP\",\n      \"index\": 0,\n      \"safetyRatings\": [\n        {\n          \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HARASSMENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        }\n      ]\n    }\n  ]\n}\n",
            headers: [],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.Gemini.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
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
            tool_call_id: "call_euQN3UTzL8HNn3jc2TzFnz",
            tool_name: "random_fact"
          }
        ],
        [random_fact_tool()],
        [model: "gemini-pro"]
      )
      #IO.inspect(response, limit: :infinity, printable_limit: :infinity)
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.__struct__ == GenAI.Message
      assert choice.message.content == "Cats have 230 bones, while humans only have 206"
    end

    
    @tag :vision
    @tag :advanced
    test "Vision Test" do
      Mimic.expect(Finch, :request, fn(request, _, _) ->
        assert request.body =~ "{\"contents\":[{\"parts\":[{\"text\":\"Describe this image\"},{\"inlineData\":{\"data\":\"/9j/4QBORXhpZgAATU0AKgAAAAgAAwEaAAUAAAABAAAAMgEbAAUAAAABAAAAOgEoAAMAAAABAAIAAAAAAAAADqYAAAAnEAAOpgAAACcQAAAAAP/tAEBQaG90b3Nob3AgMy4wADhCSU0EBgAAAAAABwABAQEAAQEAOEJJTQQlAAAAAAAQAAAAAAAAAAAAAAAAAAAAAP/iDFhJQ0NfUFJPRklMRQABAQAADEhMaW5vAhAAAG1udHJSR0IgWFlaIAfOAAIACQAGA"
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"candidates\": [\n    {\n      \"content\": {\n        \"parts\": [\n          {\n            \"text\": \"The image is a cartoon illustration of a cute white cat with orange stripes sitting in a field of flowers. The cat has big, round eyes and a small, pink nose. It is surrounded by flowers in various colors, including blue, pink, and yellow. There are also two butterflies flying around the cat. The background is a light green color with white dots. The image is drawn in a whimsical style and evokes a sense of happiness and innocence.\"\n          }\n        ],\n        \"role\": \"model\"\n      },\n      \"finishReason\": \"STOP\",\n      \"index\": 0,\n      \"safetyRatings\": [\n        {\n          \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HARASSMENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        }\n      ]\n    }\n  ],\n  \"usageMetadata\": {\n    \"promptTokenCount\": 262,\n    \"candidatesTokenCount\": 90,\n    \"totalTokenCount\": 352\n  }\n}\n",
            headers: [],
            trailers: []
          }}
      end)

      thread = GenAI.chat(:standard)
               |> GenAI.with_model(GenAI.Provider.Gemini.Models.gemini_flash_1_5())
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
      assert response.message.content =~ "The image is a cartoon illustration of a cute white cat"
    end
    
    
    @tag :vision
    @tag :advanced
    test "Vision Test - vnext session" do
      Mimic.expect(Finch, :request, fn(request, _, _) ->
        assert request.body =~ "{\"contents\":[{\"parts\":[{\"text\":\"Describe this image\"},{\"inlineData\":{\"data\":\"/9j/4QBORXhpZgAATU0AKgAAAAgAAwEaAAUAAAABAAAAMgEbAAUAAAABAAAAOgEoAAMAAAABAAIAAAAAAAAADqYAAAAnEAAOpgAAACcQAAAAAP/tAEBQaG90b3Nob3AgMy4wADhCSU0EBgAAAAAABwABAQEAAQEAOEJJTQQlAAAAAAAQAAAAAAAAAAAAAAAAAAAAAP/iDFhJQ0NfUFJPRklMRQABAQAADEhMaW5vAhAAAG1udHJSR0IgWFlaIAfOAAIACQAGA"
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\n  \"candidates\": [\n    {\n      \"content\": {\n        \"parts\": [\n          {\n            \"text\": \"The image is a cartoon illustration of a cute white cat with orange stripes sitting in a field of flowers. The cat has big, round eyes and a small, pink nose. It is surrounded by flowers in various colors, including blue, pink, and yellow. There are also two butterflies flying around the cat. The background is a light green color with white dots. The image is drawn in a whimsical style and evokes a sense of happiness and innocence.\"\n          }\n        ],\n        \"role\": \"model\"\n      },\n      \"finishReason\": \"STOP\",\n      \"index\": 0,\n      \"safetyRatings\": [\n        {\n          \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HARASSMENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        }\n      ]\n    }\n  ],\n  \"usageMetadata\": {\n    \"promptTokenCount\": 262,\n    \"candidatesTokenCount\": 90,\n    \"totalTokenCount\": 352\n  }\n}\n",
            headers: [],
            trailers: []
          }}
      end)
      
      thread = GenAI.chat(:session)
               |> GenAI.with_model(GenAI.Provider.Gemini.Models.gemini_flash_1_5())
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
      assert response.message.content =~ "The image is a cartoon illustration of a cute white cat"
    end
    
  end

end
