defmodule GenAI.Provider.Anthropic do
  import GenAI.Provider
  @api_base "https://api.anthropic.com"


  defp headers(settings) do
    auth = cond do
      key = settings[:api_key] -> {"x-api-key", key}
      key = Application.get_env(:genai, :anthropic)[:api_key] -> {"x-api-key", key}
    end
    claude_version = cond do
      key = settings[:anthropic_version] -> {"anthropic-version", key}
      key = Application.get_env(:genai, :anthropic)[:version] -> {"anthropic-version", key}
      :else -> {"anthropic-version", "2023-06-01"}
    end
    [
      auth,
      claude_version,
      {"content-type", "application/json"}
    ]
  end

  def chat(messages, _tools, settings) do
    headers = headers(settings)
    body = %{}
           |> with_required_setting(:model, settings)
           |> with_setting(:max_tokens, settings, 4096)
           |> Map.put(:messages, Enum.map(messages, &GenAI.Provider.Anthropic.MessageProtocol.message/1))
    call = GenAI.Provider.api_call(:post, "#{@api_base}/v1/messages", headers, body)
    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      chat_completion_from_json(json)
    end
  end

  defp chat_completion_from_json(json) do
    with %{
           #id: id,
           usage: %{
             input_tokens: prompt_tokens,
             output_tokens: completion_tokens
           },
           model: model,
           stop_reason: stop_reason,
           stop_sequence: nil,
           content: content
           #created: created
         } <- json do
      {:ok, message} = chat_message_from_json(content)
      finish_reason = String.to_atom(stop_reason)
                      |> case do
                           :end_turn -> :stop
                           x -> x
                         end

      choice = %GenAI.ChatCompletion.Choice{
        index: 0,
        message: message,
        finish_reason: finish_reason
      }

      completion = %GenAI.ChatCompletion{
        provider: __MODULE__,
        model: model,
        usage: %GenAI.ChatCompletion.Usage{
          prompt_tokens: prompt_tokens,
          total_tokens: prompt_tokens + completion_tokens,
          completion_tokens: completion_tokens
        },
        choices: [choice]
      }
      {:ok, completion}
    end
  end
  def chat_message_from_json(json) do
    case json do
      [%{type: "text", text: text}] -> {:ok, %GenAI.Message{role: :assistant, content: text}}
    end
  end

end
