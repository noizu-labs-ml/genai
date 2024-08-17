defmodule GenAI.Provider.Mistral do
  @moduledoc """
  This module implements the GenAI provider for Mistral AI.
  """
  @behaviour GenAI.ProviderBehaviour
  import GenAI.Provider

  @api_base "https://api.mistral.ai"

  @impl GenAI.ProviderBehaviour
  def format_tool(tool, state)
  def format_tool(tool, state) do
    {:ok, GenAI.Provider.Mistral.ToolProtocol.tool(tool), state}
  end

  @impl GenAI.ProviderBehaviour
  def format_message(message, state)
  def format_message(message, state) do
    {:ok, GenAI.Provider.Mistral.MessageProtocol.message(message), state}
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
             |> with_setting(:temperature, settings)
             |> with_setting(:top_p, settings)
             |> with_setting(:max_tokens, settings)
             |> with_setting(:safe_prompt, settings)
             |> with_setting_as(:random_seed, :seed, settings)
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


  @impl GenAI.ProviderBehaviour
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


  # Constructs the headers for Mistral API requests.
  #
  # This function retrieves the API key from either the provided settings or the application environment and constructs the necessary headers for Mistral API calls.
  defp headers(settings) do
    auth =
      cond do
        key = settings[:api_key] -> {"Authorization", "Bearer #{key}"}
        key = Application.get_env(:genai, :mistral)[:api_key] -> {"Authorization", "Bearer #{key}"}
      end
    [
      auth,
      {"content-type", "application/json"}
    ]
  end

  @doc """
  Retrieves a list of available Mistral models.

  This function calls the Mistral API to retrieve a list of models and returns them as a list of `GenAI.Model` structs.
  """
  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{@api_base}/v1/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      case json do
        %{data: models, object: "list"} ->
          models = models |> Enum.map(&model_from_json/1)
          {:ok, models}

        _ ->
          {:error, {:response, json}}
      end
    end
  end

  # Converts a JSON representation of a Mistral model to a `GenAI.Model` struct.
  defp model_from_json(json) do
    %GenAI.Model{
      model: json[:id],
      provider: __MODULE__,
      details: json
    }
  end


  defp standardize_model(model) when is_atom(model),  do: %GenAI.Model{model: model, provider: __MODULE__}
  defp standardize_model(model) when is_bitstring(model),  do: %GenAI.Model{model: model, provider: __MODULE__}
  defp standardize_model(model) do
    if GenAI.ModelProtocol.protocol_supported?(model) do
      model
    else
      raise GenAI.RequestError, "Unsupported Model"
    end
  end


  # Converts a JSON response from the Mistral chat completion API to a `GenAI.ChatCompletion` struct.
  defp chat_completion_from_json(json) do
    with %{
           id: id,
           usage: %{
             prompt_tokens: prompt_tokens,
             total_tokens: total_tokens,
             completion_tokens: completion_tokens
           },
           model: model,
           choices: choices
         } <- json do
      choices =
        Enum.map(choices, &chat_choice_from_json(id, &1))
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


  # Converts a JSON representation of a Mistral chat choice to a `GenAI.ChatCompletion.Choice` struct.
  defp chat_choice_from_json(id, json) do
    with %{
           index: index,
           message: message,
           finish_reason: finish_reason
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


  # Converts a JSON representation of a Mistral chat choice message to a `GenAI.Message` or `GenAI.Message.ToolCall` struct.
  defp chat_choice_message_from_json(_id, json) do
    case json do
      %{
        role: "assistant",
        content: content,
        tool_calls: nil
      } ->
        {:ok, %GenAI.Message{role: :assistant, content: content}}

      %{
        role: "assistant",
        content: content,
        tool_calls: tc
      } ->
        tool_calls =
          Enum.map(tc, fn tc ->
            {:ok, short_uuid} = ShortUUID.encode(UUID.uuid4())

            tc
            |> put_in([Access.key(:function), Access.key(:arguments)],
                 tc.function.arguments && Jason.decode!(tc.function.arguments, keys: :atoms)
               )
            |> put_in([Access.key(:id)], "call_#{short_uuid}")
            |> put_in([Access.key(:type)], "function")
          end)

        {:ok, %GenAI.Message.ToolCall{role: :assistant, content: content, tool_calls: tool_calls}}

      %{
        role: "assistant",
        content: content
      } ->
        {:ok, %GenAI.Message{role: :assistant, content: content}}
    end
  end


  defmodule Models do
    @moduledoc """
    Defines some common Mistral models.
    """
    def mistral_small() do
      %GenAI.Model{
        model: "mistral-small-latest",
        provider: GenAI.Provider.Mistral
      }
    end

    def mistral_medium() do
      %GenAI.Model{
        model: "mistral-medium-latest",
        provider: GenAI.Provider.Mistral
      }
    end

    def mistral_large() do
      %GenAI.Model{
        model: "mistral-large-latest",
        provider: GenAI.Provider.Mistral
      }
    end

  end
end
