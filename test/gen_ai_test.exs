defmodule GenAITest do
  use ExUnit.Case
  doctest GenAI

  def random_fact_tool() do
      {:ok, tool} = GenAI.Tool.Function.from_yaml(
        """
        name: random_fact
        description: Get a random fact
        parameters:
          type: object
          properties:
            subject:
              type: string
              description: The subject to generate a random fact for. e.g Cats
          required:
            - category
        """
      )
      tool
  end


  describe "Tool Parsing" do
    test "tool from yaml - long" do
      {:ok, sut} = GenAI.Tool.Function.from_yaml(
        """
        type: function
        function:
          name: get_current_weather
          description: Get the current weather in a given location
          parameters:
            type: object
            properties:
              location:
                type: string
                description: The city and state, e.g. San Francisco, CA
              unit:
                type: string
                enum:
                  - celsius
                  - fahrenheit
            required:
              - location
        """
      )
      assert sut.name == "get_current_weather"
      assert sut.description == "Get the current weather in a given location"
      assert sut.parameters.required == ["location"]
      assert sut.parameters.properties["location"].__struct__ == GenAI.Tool.Schema.String
      assert sut.parameters.properties["location"].description == "The city and state, e.g. San Francisco, CA"
      assert sut.parameters.properties["unit"].__struct__ == GenAI.Tool.Schema.Enum
      assert sut.parameters.properties["unit"].enum == ["celsius", "fahrenheit"]

    end

    test "tool from json - long" do
      {:ok, sut} = GenAI.Tool.Function.from_json(
        """
        {
            "type": "function",
            "function": {
              "name": "get_current_weather",
              "description": "Get the current weather in a given location",
              "parameters": {
                "type": "object",
                "properties": {
                  "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA"
                  },
                  "unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"]
                  }
                },
                "required": ["location"]
              }
            }
          }
        """
      )
      assert sut.name == "get_current_weather"
      assert sut.description == "Get the current weather in a given location"
      assert sut.parameters.required == ["location"]
      assert sut.parameters.properties["location"].__struct__ == GenAI.Tool.Schema.String
      assert sut.parameters.properties["location"].description == "The city and state, e.g. San Francisco, CA"
      assert sut.parameters.properties["unit"].__struct__ == GenAI.Tool.Schema.Enum
      assert sut.parameters.properties["unit"].enum == ["celsius", "fahrenheit"]
    end

    test "Jason.encode" do
      {:ok, sut} = GenAI.Tool.Function.from_json(
        """
        {
            "type": "function",
            "function": {
              "name": "get_current_weather",
              "description": "Get the current weather in a given location",
              "parameters": {
                "type": "object",
                "properties": {
                  "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA"
                  },
                  "unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"]
                  }
                },
                "required": ["location"]
              }
            }
          }
        """
      )
      {:ok, json} = Jason.encode(sut)
      assert json == "{\"name\":\"get_current_weather\",\"description\":\"Get the current weather in a given location\",\"parameters\":{\"type\":\"object\",\"required\":[\"location\"],\"properties\":{\"location\":{\"type\":\"string\",\"description\":\"The city and state, e.g. San Francisco, CA\"},\"unit\":{\"type\":\"string\",\"enum\":[\"celsius\",\"fahrenheit\"]}}}}"
    end

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
            body: "{\n  \"candidates\": [\n    {\n      \"content\": {\n        \"parts\": [\n          {\n            \"text\": \"Cats have 230 bones, while humans only have 206\"\n          }\n        ],\n        \"role\": \"model\"\n      },\n      \"finishReason\": \"STOP\",\n      \"index\": 0,\n      \"safetyRatings\": [\n        {\n          \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HARASSMENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        }\n      ]\n    }\n  ]\n}\n",
            headers: [],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.Gemini.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
          %GenAI.Message.ToolCall{
            role: :assistant,
            content: "Okay, here is a tool call to generate a random fact about cats:\n\n",
            tool_calls: [
              %{
                function: %{name: "random_fact", arguments: %{subject: "Cats"}},
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
            tool_call_id: "call_euQN3UTzL8HNn3jc2TzFnz",
            name: "random_fact"
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


  end

  describe "Mistral Provider" do
    test "models" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"object\":\"list\",\"data\":[{\"id\":\"open-mistral-7b\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-e163f70a5206456a9a4d9ef7073d1463\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-tiny-2312\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-98cc75a048334adead95487b1f48137b\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-tiny\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-e13d3757f7e446ffb69f2b94513a9039\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"open-mixtral-8x7b\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-17826ebf5c7341d49f9872c9e1b70c37\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-small-2312\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-19f69ea3d260488ebab7e89874da0432\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-small\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-33fc0b3856814f4ca07fc62e11dbb531\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-small-2402\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-37ae0b19a5ef4bb5874bb0469a183f49\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-small-latest\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-2c1a42bc6a5b4078811a2f85ce358ee8\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-medium-latest\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-37309bd2abf94f0fb7e27950396696eb\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-medium-2312\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-b520d4597d2443108c534aa76dbe9b68\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-medium\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-c5868cecc556473686a92ae1704d3519\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-large-latest\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-bcfea841659f47618098757ecf1e0b17\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-large-2402\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-0a41f116b4764ea7a0e442c4d97ccf53\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]},{\"id\":\"mistral-embed\",\"object\":\"model\",\"created\":1710571495,\"owned_by\":\"mistralai\",\"root\":null,\"parent\":null,\"permission\":[{\"id\":\"modelperm-3352e474406449bdbefb10d6e8087b3f\",\"object\":\"model_permission\",\"created\":1710571495,\"allow_create_engine\":false,\"allow_sampling\":true,\"allow_logprobs\":false,\"allow_search_indices\":false,\"allow_view\":true,\"allow_fine_tuning\":false,\"organization\":\"*\",\"group\":null,\"is_blocking\":false}]}]}",
            headers: [],
            trailers: []
          }
        }
      end)

      {:ok, [h|_]} = GenAI.Provider.Mistral.models()
      assert h.model == "open-mistral-7b"
    end


    test "chat - with function calls" do

      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"7bc64f64ef594781bfbeb48f7aceabf1\",\"object\":\"chat.completion\",\"created\":1710619959,\"model\":\"mistral-small-latest\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"\",\"tool_calls\":[{\"function\":{\"name\":\"random_fact\",\"arguments\":\"{\\\"category\\\": \\\"animals\\\", \\\"subject\\\": \\\"cats\\\"}\"}}]},\"finish_reason\":\"tool_calls\",\"logprobs\":null}],\"usage\":{\"prompt_tokens\":93,\"total_tokens\":122,\"completion_tokens\":29}}",
            headers: [],
            trailers: []
          }
        }
      end)

      {:ok, response} = GenAI.Provider.Mistral.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
        ],
        [random_fact_tool()],
        [model: "mistral-small-latest"]
      )
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.__struct__ == GenAI.Message.ToolCall
      [fc] = choice.message.tool_calls
      assert fc.function.name == "random_fact"
      assert fc.function.arguments[:subject] == "cats"
    end


    test "chat - with function call response" do

      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"49a7ddd8dead421784aff32558d27f69\",\"object\":\"chat.completion\",\"created\":1710623529,\"model\":\"mistral-small-latest\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"Here's a random fact about cats: Cats are awesome! Is there anything else you'd like to know?\",\"tool_calls\":null},\"finish_reason\":\"stop\",\"logprobs\":null}],\"usage\":{\"prompt_tokens\":153,\"total_tokens\":178,\"completion_tokens\":25}}",
            headers: [],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.Mistral.chat(
        [
          %GenAI.Message{role: :user, content: "Tell me a random fact about cats using a tool call."},
          %GenAI.Message.ToolCall{
            role: :assistant,
            content: "",
            tool_calls: [
              %{
                function: %{
                  name: "random_fact",
                  arguments: %{"category" => "animals", :subject => "cats"}
                },
                id: "call_CzTrgmcWofyDCVp9tgkomE",
                type: "function"
              }
            ],
            vsn: 1.0
          },
          %GenAI.Message.ToolResponse{
            response: %{
              body: "Cats are awesome, now there's a cat fact!"
            },
            tool_call_id: "call_CzTrgmcWofyDCVp9tgkomE"
          }
        ],
        [random_fact_tool()],
        [model: "mistral-small-latest"]
      )
      assert response.provider == GenAI.Provider.Mistral
      assert response.model == "mistral-small-latest"
      assert response.seed == nil
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Here's a random fact about cats: Cats are awesome! Is there anything else you'd like to know?"
      assert choice.finish_reason == :stop
    end

    test "chat" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"2360c9a32d564d869fb2f873e308d85f\",\"object\":\"chat.completion\",\"created\":1710579730,\"model\":\"mistral-small-latest\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"Hello! It's nice to connect with you. How can I assist you today?\",\"tool_calls\":null},\"finish_reason\":\"stop\",\"logprobs\":null}],\"usage\":{\"prompt_tokens\":6,\"total_tokens\":24,\"completion_tokens\":18}}",
            headers: [],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.Mistral.chat(
        [
        %GenAI.Message{role: :user, content: "Say Hello."},
        ],
        nil,
        [model: "mistral-small-latest"]
      )
      assert response.provider == GenAI.Provider.Mistral
      assert response.model == "mistral-small-latest"
      assert response.seed == nil
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Hello! It's nice to connect with you. How can I assist you today?"
      assert choice.finish_reason == :stop
    end
  end


  describe "OpenAI Provider" do
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
  end

  describe "GenAI Context" do
    test "Simple inference run" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"73d082010b2741a38528d9c9e19bf2aa\",\"object\":\"chat.completion\",\"created\":1710628734,\"model\":\"mistral-small-latest\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"I'm sorry, Dave. I'm afraid I can't do that.\\n\\nNow, to answer your question, \\\"2001: A Space Odyssey\\\" is a 1968 science fiction film directed by Stanley Kubrick and written by Kubrick and Arthur C. Clarke. The film follows a voyage to Jupiter with the sentient computer HAL after the discovery of a mysterious black monolith affecting human evolution. The film deals with themes of human evolution, technology, artificial intelligence, and extraterrestrial life. It is often considered one of the greatest films of all time.\",\"tool_calls\":null},\"finish_reason\":\"stop\",\"logprobs\":null}],\"usage\":{\"prompt_tokens\":41,\"total_tokens\":171,\"completion_tokens\":130}}",
            headers: [],
            trailers: []
          }}
      end)
      thread = GenAI.chat()
               |> GenAI.with_model(GenAI.Provider.Mistral.Models.mistral_small())
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_api_key(GenAI.Provider.Gemini, "invalid")
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL"})
               |> GenAI.with_message(%GenAI.Message{role: :assistant, content: "I'm afraid I can't do that Dave"})
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "What is the movie \"2001: A Space Odyssey\" about?"})
      {:ok, sut} = GenAI.run(thread)
      assert sut == %GenAI.ChatCompletion{
               id: "73d082010b2741a38528d9c9e19bf2aa",
               model: "mistral-small-latest",
               provider: GenAI.Provider.Mistral,
               seed: nil,
               choices: [
                 %GenAI.ChatCompletion.Choice{
                   index: 0,
                   message: %GenAI.Message{
                     role: :assistant,
                     content: "I'm sorry, Dave. I'm afraid I can't do that.\n\nNow, to answer your question, \"2001: A Space Odyssey\" is a 1968 science fiction film directed by Stanley Kubrick and written by Kubrick and Arthur C. Clarke. The film follows a voyage to Jupiter with the sentient computer HAL after the discovery of a mysterious black monolith affecting human evolution. The film deals with themes of human evolution, technology, artificial intelligence, and extraterrestrial life. It is often considered one of the greatest films of all time.",
                     vsn: 1.0
                   },
                   finish_reason: :stop
                 }
               ],
               usage: %GenAI.ChatCompletion.Usage{
                 prompt_tokens: 41,
                 total_tokens: 171,
                 completion_tokens: 130
               },
               details: nil,
               vsn: 1.0
             }
      Mimic.expect(Finch, :request, fn(request, _finch, _http_options) ->
        if request.body =~ "[{\"category\":\"HARM_CATEGORY_DANGEROUS_CONTENT\",\"threshold\":\"BLOCK_ONLY_HIGH\"}]" do
          {:ok,
            %Finch.Response{
              status: 200,
              body: "{\n  \"candidates\": [\n    {\n      \"content\": {\n        \"parts\": [\n          {\n            \"text\": \"I'm sorry, Dave. I'm afraid I can't do that.\"\n          }\n        ],\n        \"role\": \"model\"\n      },\n      \"finishReason\": \"STOP\",\n      \"index\": 0,\n      \"safetyRatings\": [\n        {\n          \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_HARASSMENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        },\n        {\n          \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n          \"probability\": \"NEGLIGIBLE\"\n        }\n      ]\n    }\n  ],\n  \"promptFeedback\": {\n    \"safetyRatings\": [\n      {\n        \"category\": \"HARM_CATEGORY_SEXUALLY_EXPLICIT\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_HATE_SPEECH\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_HARASSMENT\",\n        \"probability\": \"NEGLIGIBLE\"\n      },\n      {\n        \"category\": \"HARM_CATEGORY_DANGEROUS_CONTENT\",\n        \"probability\": \"NEGLIGIBLE\"\n      }\n    ]\n  }\n}\n",
              headers: [],
              trailers: []
            }}
        end
      end)

      thread = thread
               |> GenAI.with_model(GenAI.Provider.Gemini.Models.gemini_pro())
               |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ANY")
               |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ONLY_HIGH")

      {:ok, sut} = GenAI.run(thread)

      assert sut.model == "gemini-pro"
    end

  end

end
