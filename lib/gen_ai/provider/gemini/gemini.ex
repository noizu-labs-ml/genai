defmodule GenAI.Provider.Gemini do
  import GenAI.Provider
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



  @impl GenAI.ProviderBehaviour
  def format_tool(tool, state)
  def format_tool(tool, state) do
    {:ok, GenAI.Provider.Gemini.ToolProtocol.tool(tool), state}
  end

  @impl GenAI.ProviderBehaviour
  def format_message(message, state)
  def format_message(message, state) do
    {:ok, GenAI.Provider.Gemini.MessageProtocol.message(message), state}
  end

  defp completion_url(model, provider_settings) do
    with {:ok, model_name} <- GenAI.ModelProtocol.model(model) do
      api_key = api_key(provider_settings)
      url = "https://generativelanguage.googleapis.com/v1beta/models/#{model_name}:generateContent?key=#{api_key}"
      {:ok, url}
    end
  end

  defp generation_config(settings)
  defp generation_config(settings) do
    config = %{}
             |> with_setting_as(:stop_sequences, :stop, settings)
             |> with_setting_as(:max_output_tokens, :max_tokens, settings)
             |> with_setting(:temperature, settings)
             |> with_setting(:top_p, settings)
             |> with_setting(:top_k, settings)
    unless config == %{}, do: config
  end

  defp safety_settings(settings)
  defp safety_settings(settings) do
    # Hack to handle list passed as array or as nested array of settings
    config = Keyword.get_values(settings, :safety_setting)
             |> Enum.group_by(& &1[:category])
             |> Enum.map(
                  fn
                    {_, [h|_]} ->
                      # @todo inherit/fall through support - should be implemented using a special setting node type, logic here should not be required.
                      h
                    _ -> nil
                  end)
             |> Enum.reject(&is_nil/1)
    unless config == [], do: config
  end

  @impl GenAI.ProviderBehaviour
  def run(state) do
    provider = __MODULE__
    with {:ok, provider_settings, state} <- GenAI.Thread.StateProtocol.provider_settings(state, provider),
         {:ok, settings, state} <- GenAI.Thread.StateProtocol.settings(state),
         {:ok, model, state} <- GenAI.Thread.StateProtocol.model(state),
         {:ok, model_name} <- GenAI.ModelProtocol.model(model),
         {:ok, tools, state} <- GenAI.Thread.StateProtocol.tools(state, provider),
         {:ok, messages, state} <- GenAI.Thread.StateProtocol.messages(state, provider),
         {:ok, completion_url} = completion_url(model, provider_settings) do

      # Headers
      headers = headers(provider_settings)

      # Normalize Messages
      messages = messages
                 |> normalize_messages()

      # Tool Declarations
      tool_declaration = with [_|_] <- tools do
        [%{function_declarations: tools}]
      end

      body = %{contents: messages}
             |> optional_field(:generation_config, generation_config(settings))
             |> optional_field(:safety_settings, safety_settings(settings))
             |> optional_field(:tools, tool_declaration)

      call = api_call(:post, completion_url, headers, body)
      with {:ok, %Finch.Response{status: 200, body: body}} <- call,
           {:ok, json} <- Jason.decode(body, keys: :atoms),
        {:ok, response} <- completion_from_json(model_name, json) do
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
    # hack - translate safety settings to required format:
    settings = Enum.map(settings,
      fn
        {:safety_setting, v} -> {{:__multi__, :safety_setting}, v}
        {k, v} -> {k, v}
      end
    )
    |> Enum.reverse()
    provider_settings = Enum.filter(settings, fn {k,_} -> k in [:api_key, :api_org] end)
    chat(settings[:model], messages, tools, settings, provider_settings)
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

    def gemini_pro_1_0() do
      %GenAI.Model{
        model: "gemini-1.0-pro",
        provider: GenAI.Provider.Gemini
      }
    end

    def gemini_pro_1_5() do
      %GenAI.Model{
        model: "gemini-1.5-pro",
        provider: GenAI.Provider.Gemini
      }
    end

    def gemini_flash_1_5() do
      %GenAI.Model{
        model: "gemini-1.5-flash",
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
