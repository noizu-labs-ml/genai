defmodule GenAI.Provider.OpenAI do
  import GenAI.Provider
  @api_base "https://api.openai.com"
  @behaviour GenAI.ProviderBehaviour


  defp standardize_model(model) when is_atom(model),  do: %GenAI.Model{model: model, provider: __MODULE__}
  defp standardize_model(model) when is_bitstring(model),  do: %GenAI.Model{model: model, provider: __MODULE__}
  defp standardize_model(model) do
    if GenAI.ModelProtocol.protocol_supported?(model) do
      model
    else
      raise GenAI.RequestError, "Unsupported Model"
    end
  end

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

  @impl GenAI.ProviderBehaviour
  def format_tool(tool, state)
  def format_tool(tool, state) do
    {:ok, GenAI.Provider.OpenAI.ToolProtocol.tool(tool), state}
  end

  @impl GenAI.ProviderBehaviour
  def format_message(message, state)
  def format_message(message, state) do
    {:ok, GenAI.Provider.OpenAI.MessageProtocol.message(message), state}
  end

  @impl GenAI.ProviderBehaviour
  def run(state) do
    provider = __MODULE__
    with {:ok, provider_settings, state} <- GenAI.Thread.StateProtocol.provider_settings(state, provider),
         {:ok, settings, state} <- GenAI.Thread.StateProtocol.settings(state),
         {:ok, model, state} <- GenAI.Thread.StateProtocol.model(state),
         {:ok, model_name} <- GenAI.ModelProtocol.model(model),
         {:ok, tools, state} <- GenAI.Thread.StateProtocol.tools(state, provider),
         {:ok, messages, state} <- GenAI.Thread.StateProtocol.messages(state, provider) do
      headers = headers(provider_settings)

      body = %{
               model: model_name,
               messages: messages
             }
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
                  fn
                    body ->
                      unless tools == [] do
                        body
                        |> with_setting(:tool_choice, settings)
                        |> Map.put(:tools, tools)
                      else
                        body
                      end
                  end
                )

      call = GenAI.Provider.api_call(:post, "#{@api_base}/v1/chat/completions", headers, body)
      with {:ok, %Finch.Response{status: 200, body: response_body}} <- call,
           {:ok, json} <- Jason.decode(response_body, keys: :atoms),
           {:ok, response} <- chat_completion_from_json(json) do
        response = put_in(response, [Access.key(:seed)], body[:random_seed])
        {:ok, response, state}
      end
    else
      error = {:error, _} -> error
      error -> {:error, error}
    end
  end


  def chat(model, messages, tools, hyper_parameters, provider_settings \\ []) do
    with state <-  %GenAI.Thread.State{},
         {:ok, state} <- GenAI.Thread.StateProtocol.with_model(state, standardize_model(model)),
         {:ok, state} <- GenAI.Thread.StateProtocol.with_provider_settings(state, __MODULE__, provider_settings),
         {:ok, state} <- GenAI.Thread.StateProtocol.with_settings(state, hyper_parameters),
         {:ok, state} <- GenAI.Thread.StateProtocol.with_tools(state, tools),
         {:ok, state} <- GenAI.Thread.StateProtocol.with_messages(state, messages)
      do
      case run(state) do
        {:ok, response, _} -> {:ok, response}
        error -> error
      end
    end
  end


  @doc """
  Sends a chat completion request to the Mistral API.
  This function constructs the request body based on the provided messages, tools, and settings, sends the request to the Mistral API, and returns a `GenAI.ChatCompletion` struct with the response.
  """
  # @deprecated "This function is deprecated. Use `GenAI.Thread.chat/5` instead."
  def chat(messages, tools, settings) do
    settings = settings |> Enum.reverse()
    provider_settings = Enum.filter(settings, fn {k,_} -> k in [:api_key, :api_org] end)
    chat(settings[:model], messages, tools, settings, provider_settings)
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
