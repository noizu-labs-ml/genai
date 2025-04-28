defmodule GenAITest do
  # import GenAI.Test.Support.Common
  use ExUnit.Case
  doctest GenAI

  describe "GenAI Context" do

    @tag :live
    @tag :advanced
    @tag provider: :mistral
    @tag thread: :legacy
    test "Advanced Context run" do
      thread = GenAI.chat(:standard)
               |> GenAI.with_model(GenAI.Provider.Mistral.Models.mistral_small())
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_api_key(GenAI.Provider.Gemini, "invalid")
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL"})
               |> GenAI.with_message(%GenAI.Message{role: :assistant, content: "I'm afraid I can't do that Dave"})
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "What is the movie \"2001: A Space Odyssey\" about and who directed it?"})
      {:ok, sut} = GenAI.run(thread)
      response = sut.choices |> hd()
      assert response.message.content =~ "Stanley Kubrick"
    end
    
    @tag :live
    @tag :advanced
    @tag provider: :mistral
    @tag thread: :session
    test "Advanced Context run - vnext session" do
      thread = GenAI.chat(:session)
               |> GenAI.with_model(GenAI.Provider.Mistral.Models.mistral_small())
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_api_key(GenAI.Provider.Gemini, "invalid")
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL"})
               |> GenAI.with_message(%GenAI.Message{role: :assistant, content: "I'm afraid I can't do that Dave"})
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "What is the movie \"2001: A Space Odyssey\" about and who directed it?"})
      {:ok, sut} = GenAI.run(thread)
      response = sut.choices |> hd()
      assert response.message.content =~ "Stanley Kubrick"
    end
    
    @tag provider: :mistral
    @tag thread: :legacy
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
      assert %GenAI.ChatCompletion{
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
               details: _,
               vsn: 1.0
             } = sut


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
    
    
    @tag provider: :mistral
    @tag thread: :session
    test "Simple inference run - vnext session" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"73d082010b2741a38528d9c9e19bf2aa\",\"object\":\"chat.completion\",\"created\":1710628734,\"model\":\"mistral-small-latest\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"I'm sorry, Dave. I'm afraid I can't do that.\\n\\nNow, to answer your question, \\\"2001: A Space Odyssey\\\" is a 1968 science fiction film directed by Stanley Kubrick and written by Kubrick and Arthur C. Clarke. The film follows a voyage to Jupiter with the sentient computer HAL after the discovery of a mysterious black monolith affecting human evolution. The film deals with themes of human evolution, technology, artificial intelligence, and extraterrestrial life. It is often considered one of the greatest films of all time.\",\"tool_calls\":null},\"finish_reason\":\"stop\",\"logprobs\":null}],\"usage\":{\"prompt_tokens\":41,\"total_tokens\":171,\"completion_tokens\":130}}",
            headers: [],
            trailers: []
          }}
      end)
      thread = GenAI.chat(:session)
               |> GenAI.with_model(GenAI.Provider.Mistral.Models.mistral_small())
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_api_key(GenAI.Provider.Gemini, "invalid")
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL"})
               |> GenAI.with_message(%GenAI.Message{role: :assistant, content: "I'm afraid I can't do that Dave"})
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "What is the movie \"2001: A Space Odyssey\" about?"})
      {:ok, sut} = GenAI.run(thread)
      assert %GenAI.ChatCompletion{
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
               details: _,
               vsn: 1.0
             } = sut
      
      
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
