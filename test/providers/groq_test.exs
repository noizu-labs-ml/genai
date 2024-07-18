defmodule GenAI.Provider.GroqTest do
  use ExUnit.Case
  #import GenAI.Test.Support.Common
  @moduletag provider: :groq


  describe "Groq Provider" do
    test "models" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"object\":\"list\",\"data\":[{\"id\":\"gemma2-9b-it\",\"object\":\"model\",\"created\":1693721698,\"owned_by\":\"Google\",\"active\":true,\"context_window\":8192},{\"id\":\"gemma-7b-it\",\"object\":\"model\",\"created\":1693721698,\"owned_by\":\"Google\",\"active\":true,\"context_window\":8192},{\"id\":\"llama3-70b-8192\",\"object\":\"model\",\"created\":1693721698,\"owned_by\":\"Meta\",\"active\":true,\"context_window\":8192},{\"id\":\"llama3-8b-8192\",\"object\":\"model\",\"created\":1693721698,\"owned_by\":\"Meta\",\"active\":true,\"context_window\":8192},{\"id\":\"llama3-groq-70b-8192-tool-use-preview\",\"object\":\"model\",\"created\":1693721698,\"owned_by\":\"Groq\",\"active\":true,\"context_window\":8192},{\"id\":\"llama3-groq-8b-8192-tool-use-preview\",\"object\":\"model\",\"created\":1693721698,\"owned_by\":\"Groq\",\"active\":true,\"context_window\":8192},{\"id\":\"mixtral-8x7b-32768\",\"object\":\"model\",\"created\":1693721698,\"owned_by\":\"Mistral AI\",\"active\":true,\"context_window\":32768},{\"id\":\"whisper-large-v3\",\"object\":\"model\",\"created\":1693721698,\"owned_by\":\"OpenAI\",\"active\":true,\"context_window\":1500}]}\n",
            headers: [
              {"date", "Thu, 18 Jul 2024 22:23:33 GMT"},
              {"content-type", "application/json"},
              {"content-length", "1015"},
              {"connection", "keep-alive"},
              {"cache-control",
                "private, max-age=0, no-store, no-cache, must-revalidate"},
              {"vary", "Origin"},
              {"x-request-id", "req_01j33z327vev19960xt301yghq"},
              {"via", "1.1 google"},
              {"alt-svc", "h3=\":443\"; ma=86400"},
              {"cf-cache-status", "DYNAMIC"},
              {"set-cookie",
                "__cf_bm=ZUmv8p9e1DnHrafTXxS2lGjayBjdgFZflQWTuZ.B5yU-1721341413-1.0.1.1-gO_s_9eM1KKKM9gYKxELoXYfsqpk3YFGesvg_XdoRdtmSjFw0EpKckOrnU04Nz9whb9Buood3T_IcNDhpJySYw; path=/; expires=Thu, 18-Jul-24 22:53:33 GMT; domain=.groq.com; HttpOnly; Secure; SameSite=None"},
              {"server", "cloudflare"},
              {"cf-ray", "8a55e07adf4052f5-LAX"}
            ],
            trailers: []
          }}
      end)

      {:ok, models} = GenAI.Provider.Groq.models()
      sut = Enum.find_value(models, & &1.model == "gemma2-9b-it" && &1)
      assert not is_nil(sut)
    end

    test "chat" do
      Mimic.expect(Finch, :request, fn(_, _, _) ->
        {:ok,
          %Finch.Response{
            status: 200,
            body: "{\"id\":\"chatcmpl-5a48bf22-02fd-4e25-807c-e62708032525\",\"object\":\"chat.completion\",\"created\":1721341683,\"model\":\"llama3-8b-8192\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"Hello! It's nice to meet you. Is there something I can help you with, or would you like to chat?\"},\"logprobs\":null,\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":13,\"prompt_time\":0.003720671,\"completion_tokens\":26,\"completion_time\":0.019903288,\"total_tokens\":39,\"total_time\":0.023623959},\"system_fingerprint\":\"fp_179b0f92c9\",\"x_groq\":{\"id\":\"req_01j33zb9n5egnsp5355jpa48dw\"}}\n",
            headers: [
              {"date", "Thu, 18 Jul 2024 22:28:03 GMT"},
              {"content-type", "application/json"},
              {"content-length", "568"},
              {"connection", "keep-alive"},
              {"cache-control",
                "private, max-age=0, no-store, no-cache, must-revalidate"},
              {"vary", "Origin"},
              {"x-ratelimit-limit-requests", "14400"},
              {"x-ratelimit-limit-tokens", "30000"},
              {"x-ratelimit-remaining-requests", "14399"},
              {"x-ratelimit-remaining-tokens", "29993"},
              {"x-ratelimit-reset-requests", "6s"},
              {"x-ratelimit-reset-tokens", "14ms"},
              {"x-request-id", "req_01j33zb9n5egnsp5355jpa48dw"},
              {"via", "1.1 google"},
              {"alt-svc", "h3=\":443\"; ma=86400"},
              {"cf-cache-status", "DYNAMIC"},
              {"set-cookie",
                "__cf_bm=dbTC4OQk8T1Q7qCHdph7j.EbnEjLQiGqxtmNVOLwfsU-1721341683-1.0.1.1-Bf0qphkuWwX2vrR3sJxR79JBdoMjGmzF9OjcUJJ3rE1yluU3J9r6LvTXq_D5RRB6F4oGbIRITHwNqyAXVqb67A; path=/; expires=Thu, 18-Jul-24 22:58:03 GMT; domain=.groq.com; HttpOnly; Secure; SameSite=None"},
              {"server", "cloudflare"},
              {"cf-ray", "8a55e710de4069a4-LAX"}
            ],
            trailers: []
          }}
      end)

      {:ok, response} = GenAI.Provider.Groq.chat(
        [
          %GenAI.Message{role: :user, content: "Say Hello."},
        ],
        nil,
        [model: GenAI.Provider.Groq.Models.llama3_8b().model ]
      )
      assert response.provider == GenAI.Provider.Groq
      assert response.model == "llama3-8b-8192"
      assert response.seed == nil
      choice = List.first(response.choices)
      assert choice.index == 0
      assert choice.message.role == :assistant
      assert choice.message.content == "Hello! It's nice to meet you. Is there something I can help you with, or would you like to chat?"
      assert choice.finish_reason == :stop
    end
  end

end
