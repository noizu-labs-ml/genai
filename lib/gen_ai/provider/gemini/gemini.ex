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
    model = settings[:model] || raise(GenAI.RequestError, "required")
    url = "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}"
    messages = Enum.map(messages, &GenAI.Provider.Gemini.MessageProtocol.message/1)
               |> normalize_messages()
    generation_config = %{}
                        |> with_setting_as(:stop_sequences, :stop, settings)
                        |> with_setting_as(:max_output_tokens, :max_tokens, settings)
                        |> with_setting(:temperature, settings)
                        |> with_setting(:top_p, settings)
                        |> with_setting(:top_k, settings)
                        |> then(& &1 == %{} && nil || &1)

    safety_settings = Keyword.get_values(settings, :safety_setting)
                      |> Enum.group_by(& &1[:category])
                      |> Enum.map(
                           fn
                             {_, [h|_]} ->
                               # @todo inherit/fall through support
                               h
                             _ -> nil
                           end)
                      |> Enum.reject(&is_nil/1)
                      |> then(& &1 == [] && nil || &1)

    body = %{contents: messages}
           |> optional_field(:generation_config, generation_config)
           |> optional_field(:safety_settings, safety_settings)

    body = if is_list(tools) and length(tools) > 0 do
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


  def normalize_messages(messages, acc \\ [])

  def normalize_messages([%{role: :user} = a, %{role: :user} = b|t], acc) do
    a =%{a| parts: a.parts ++ [%{text:  "\n\n<check-in>ack?</check-in>"}]}
    patch = %{
      role: :model,
      parts: [%{text: "ack"}],
    }
    normalize_messages(t, [b, patch, a | acc])
  end
  def normalize_messages([%{role: :model} = a, %{role: :model} = b|t], acc) do
    patch = %{
      role: :user,
      parts: [%{text: "continue"}]
    }
    [b, patch, a]
    normalize_messages(t, [b, patch, a | acc])
  end
  def normalize_messages([h|t], acc), do: normalize_messages(t, [h|acc])
  def normalize_messages([], acc), do: Enum.reverse(acc)


  defp completion_from_json(model, json) do
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
  defp chat_choice_from_json(json) do
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
  defp chat_choice_message_from_json(json) do
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


  defmodule Models do

    def gemini_pro() do
      %GenAI.Model{
        model: "gemini-pro",
        provider: GenAI.Provider.Gemini
      }
    end

    def gemini_pro_vision() do
      %GenAI.Model{
        model: "gemini-pro-vision",
        provider: GenAI.Provider.Gemini
      }
    end

  end
end
