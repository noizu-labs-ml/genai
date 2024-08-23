defmodule GenAI.Provider.MistralTest do
  use ExUnit.Case
  import GenAI.Test.Support.Common
  @moduletag provider: :mistral

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

end
