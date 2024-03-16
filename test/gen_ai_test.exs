defmodule GenAITest do
  use ExUnit.Case
  doctest GenAI


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

end
