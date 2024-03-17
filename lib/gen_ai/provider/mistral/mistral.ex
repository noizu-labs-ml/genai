defmodule GenAI.Provider.Mistral do
  @moduledoc """
  This module implements the GenAI provider for Mistral AI.
  """

  import GenAI.Provider

  @api_base "https://api.mistral.ai"


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

  @doc """
  Sends a chat completion request to the Mistral API.

  This function constructs the request body based on the provided messages, tools, and settings, sends the request to the Mistral API, and returns a `GenAI.ChatCompletion` struct with the response.
  """
  def chat(messages, tools, settings) do
    headers = headers(settings)

    body = %{}
           |> with_required_setting(:model, settings)
           |> with_setting(:temperature, settings)
           |> with_setting(:top_p, settings)
           |> with_setting(:max_tokens, settings)
           |> with_setting(:safe_prompt, settings)
           |> with_setting_as(:seed, :random_seed, settings)
           |> then(fn body ->
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
  end
end
