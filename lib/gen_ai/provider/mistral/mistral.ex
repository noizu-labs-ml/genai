defmodule GenAI.Provider.Mistral do
  import GenAI.Provider
  @api_base "https://api.mistral.ai"

  defp headers(settings) do
    auth = cond do
      key = settings[:api_key] -> {"Authorization", "Bearer #{key}"}
      key = Application.get_env(:genai, :mistral)[:api_key] -> {"Authorization", "Bearer #{key}"}
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
           |> with_setting(:temperature, settings)
           |> with_setting(:top_p, settings)
           |> with_setting(:max_tokens, settings)
           |> with_setting(:safe_prompt, settings)
           |> with_setting_as(:seed, :random_seed, settings)
           |> then(
                fn(body) ->
                  if tools do
                    body
                    |> with_setting(:tool_choice, settings)
                    |> Map.put(:tools, Enum.map(tools, &GenAI.Provider.Mistral.ToolProtocol.tool/1))
                  else
                    body
                  end
                end)
           |> Map.put(:messages, Enum.map(messages, &GenAI.Provider.Mistral.MessageProtocol.message/1))
    call = GenAI.Provider.api_call(:post, "#{@api_base}/v1/chat/completions", headers, body)
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
            |> put_in([Access.key(:function), Access.key(:arguments)],Jason.decode!(x.function.arguments))
            |> put_in([Access.key(:function), Access.key(:id)], "call_" <> UUID.uuid4())
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



end
