defmodule GenAI.Provider.Gemini do
  import GenAI.Provider

  defp headers(_settings) do
    [
      {"content-type", "application/json"}
    ]
  end

  defp api_key(settings) do
    cond do
      key = settings[:api_key] -> key
      key = Application.get_env(:genai, :gemini)[:api_key] -> key
    end
  end

  def models(settings \\ []) do
    api_key = api_key(settings)
    headers = headers(settings)
    url = "https://generativelanguage.googleapis.com/v1beta/models?key=#{api_key}"
    call = GenAI.Provider.api_call(:get, url, headers)
    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{models: models} <- json do
        models = Enum.map(models, &model_from_json/1)
        {:ok, models}
      end
    end
  end

  defp model_from_json(json) do
    %GenAI.Model{
      model: json[:name],
      provider: __MODULE__,
      details: json
    }
  end

  def chat(messages, tools, settings) do
    api_key = api_key(settings)
    headers = headers(settings)
    model = settings[:model] || throw "required"
    url = "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}"
    messages = Enum.map(messages, &GenAI.Provider.Gemini.MessageProtocol.message/1)
    body = %{contents: messages}
    body = if tools do
      x = Enum.map(tools, &GenAI.Provider.Gemini.ToolProtocol.tool/1)
      Map.put(body, :tools, [%{function_declarations: x}])
    else
      body
    end

    call = api_call(:post, url, headers, body)
    #|> IO.inspect(limit: :infinity, printable_limit: :infinity)
    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      completion_from_json(model, json)
    end
  end

  def completion_from_json(model, json) do
    with %{candidates: choices} <- json do
      choices = Enum.map(choices, &chat_choice_from_json/1)
                |> Enum.map(fn {:ok, c} -> c end)
      completion = %GenAI.ChatCompletion{
        provider: __MODULE__,
        model: model,
        usage: %GenAI.ChatCompletion.Usage{},
        choices: choices,
        details: json
      }
      {:ok, completion}
    end
  end
  def chat_choice_from_json(json) do
    with %{
           index: index,
           content: message,
           finishReason: finish_reason
         } <- json do
      with {:ok, message} <- chat_choice_message_from_json(message) do
        choice = %GenAI.ChatCompletion.Choice{
          index: index,
          message: message,
          finish_reason: String.downcase(finish_reason) |> String.to_atom()
        }
        {:ok, choice}
      end
    end
  end
  def chat_choice_message_from_json(json) do
    case json do
      %{
        role: "model",
        parts: [%{text: text}]
      } ->
        msg = %GenAI.Message{
          role: :assistant,
          content: text
        }
        {:ok, msg}
      %{
        role: "model",
        parts: [%{functionCall: %{name: name, args: arguments}}]
      } ->
        # TODO multi call support
        {:ok, short_uuid} = ShortUUID.encode(UUID.uuid4())

        call = %{
          function: %{
            name: name,
            arguments: arguments,
          },
          id: "call_#{short_uuid}",
          type: "function"
        }
        {:ok, %GenAI.Message.ToolCall{role: :assistant, content: "", tool_calls: [call]}}
    end
  end

end
