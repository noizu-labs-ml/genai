defmodule GenAI.Provider.OpenAI do
  import GenAI.Provider
  @api_base "https://api.openai.com"

  defp headers(settings) do
    auth = cond do
      key = settings[:api_key] -> {"Authorization", "Bearer #{key}"}
      key = Application.get_env(:genai, :openai)[:api_key] -> {"Authorization", "Bearer #{key}"}
    end
    [
      auth,
      {"content-type", "application/json"}
    ]
  end

  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{@api_base}/v1/models", headers)
    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do

      with %{data: models, object: "list"} <- json do
        models = models
                 |> Enum.map(&model_from_json/1)
        {:ok, models}
      else
        _ -> {:error, {:response, json}}
      end
    end
  end
  defp model_from_json(json) do
    %GenAI.Model{
      model: json[:id],
      provider: __MODULE__,
      details: json
    }
  end

  def chat(messages, tools, settings) do
    headers = headers(settings)

    body = %{}
           |> with_required_setting(:model, settings)
           |> with_setting(:frequency_penalty, settings)
           |> with_setting(:logprobe, settings)
           |> with_setting(:top_logprobs, settings)
           |> with_setting(:logit_bias, settings)
           |> with_setting(:max_tokens, settings)
           |> with_setting_as(:n, :completion_choices, settings)
           |> with_setting(:presence_penalty, settings)
           |> with_setting(:response_format, settings)
           |> with_setting(:seed, settings)
           |> with_setting(:stop, settings)
           |> with_setting(:temperature, settings)
           |> with_setting(:top_p, settings)
           |> with_setting(:user, settings)
           |> then(
                fn(body) ->
                  if is_list(tools) and length(tools) > 0 do
                    body
                    |> with_setting(:tool_choice, settings)
                    |> Map.put(:tools, Enum.map(tools, &GenAI.Provider.OpenAI.ToolProtocol.tool/1))
                  else
                    body
                  end
                end)
           |> Map.put(:messages, Enum.map(messages, &GenAI.Provider.OpenAI.MessageProtocol.message/1))
    call = GenAI.Provider.api_call(:post, "#{@api_base}/v1/chat/completions", headers, body)
    #IO.inspect(call, limit: :infinity, printable_limit: :infinity)
    with {:ok, %Finch.Response{status: 200, body: response_body}} <- call,
         {:ok, json} <- Jason.decode(response_body, keys: :atoms),
         {:ok, response} <- chat_completion_from_json(json) do
      response = put_in(response, [Access.key(:seed)], body[:random_seed])
      {:ok, response}
    end
  end

  defp chat_completion_from_json(json) do
    with %{
           id: id,
           usage: %{
             prompt_tokens: prompt_tokens,
             total_tokens: total_tokens,
             completion_tokens: completion_tokens
           },
           model: model,
           #created: created,
           choices: choices
         } <- json do
      choices = Enum.map(choices, &chat_choice_from_json(id, &1))
                |> Enum.map(fn {:ok, c} -> c end)
      completion = %GenAI.ChatCompletion{
        id: id,
        provider: __MODULE__,
        model: model,
        usage: %GenAI.ChatCompletion.Usage{
          prompt_tokens: prompt_tokens,
          total_tokens: total_tokens,
          completion_tokens: completion_tokens
        },
        choices: choices
      }
      {:ok, completion}
    end
  end

  defp chat_choice_from_json(id, json) do
    with %{
           index: index,
           message: message,
           finish_reason: finish_reason,
         } <- json do
      with {:ok, message} <- chat_choice_message_from_json(id, message) do
        choice = %GenAI.ChatCompletion.Choice{
          index: index,
          message: message,
          finish_reason: String.to_atom(finish_reason)
        }
        {:ok, choice}
      end
    end
  end
  defp chat_choice_message_from_json(_id, json) do
    case json do
      %{
        role: "assistant",
        content: content,
        tool_calls: nil
      } ->
        msg = %GenAI.Message{
          role: :assistant,
          content: content
        }
        {:ok, msg}
      %{
        role: "assistant",
        content: content,
        tool_calls: tc
      } ->
        x = Enum.map(tc, fn
          (%{function: _} = x) ->
            x
            |> put_in([Access.key(:function), Access.key(:arguments)],Jason.decode!(x.function.arguments, keys: :atoms))
            #|> put_in([Access.key(:function), Access.key(:identifier)], UUID.uuid4())
        end)
        {:ok, %GenAI.Message.ToolCall{role: :assistant, content: content, tool_calls: x}}
      %{
        role: "assistant",
        content: content,
      } ->
        msg = %GenAI.Message{
          role: :assistant,
          content: content
        }
        {:ok, msg}
    end
  end

  defmodule Models do

    def gpt_3_5_turbo() do
     %GenAI.Model{
       model: "gpt-3.5-turbo",
       provider: GenAI.Provider.OpenAI
     }
    end

    def gpt_4() do
      %GenAI.Model{
        model: "gpt-4",
        provider: GenAI.Provider.OpenAI
      }
    end

    def gpt_4_turbo() do
      %GenAI.Model{
        model: "gpt-4-turbo-preview",
        provider: GenAI.Provider.OpenAI
      }
    end

    def gpt_4_vision() do
      %GenAI.Model{
        model: "gpt-4-vision-preview",
        provider: GenAI.Provider.OpenAI
      }
    end

    def gpt_3_5_turbo_16k() do
      %GenAI.Model{
        model: "gpt-3.5-turbo-16k",
        provider: GenAI.Provider.OpenAI
      }
    end



  end
end
