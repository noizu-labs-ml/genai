defmodule GenAI.Provider.Anthropic do
  import GenAI.Provider
  @api_base "https://api.anthropic.com"
  @behaviour GenAI.ProviderBehaviour
  @default_system_prompt nil

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

  # @TODO - support tool_choice option
  defp tool_system_prompt(nil), do: nil
  defp tool_system_prompt([]), do: nil
  defp tool_system_prompt(tools) do
    tools = tools
            |> Jason.encode!()
            |> Jason.decode!()
    tools = %{tools: tools}
    with {:ok, yaml} <- Ymlr.document(tools) do
      yaml = String.trim_leading(yaml, "---\n")
      prompt =
      """
      Tool Usage
      ==============
      The following tools are available for use in this conversation.
      You may call them like this:
      <function_calls>
        <invoke>
          <tool_name>$TOOL_NAME</tool_name>
          <parameters>$PARAMETERS_JSON</parameters>
        </invoke>
      </function_calls>

      Here  are the available tools:
      ```yaml
      #{yaml}
      ```
      """
      {:ok, prompt}
    end
  end

  defp normalize_system_prompt(messages, tools, settings, model_settings,  provider_settings)
  defp normalize_system_prompt(_, tools, settings, model_settings,  provider_settings) do
    system_prompt = cond do
      Keyword.has_key?(settings, :system_prompt) -> settings[:system_prompt]
      Keyword.has_key?(model_settings, :system_prompt) -> model_settings[:system_prompt]
      Keyword.has_key?(provider_settings, :system_prompt) -> provider_settings[:system_prompt]
      :else -> @default_system_prompt
    end
    with {:ok, tool_usage_prompt} <- tool_system_prompt(tools) do
      if system_prompt do
        system_prompt <> "\n-----\n" <> tool_usage_prompt
      else
        tool_usage_prompt
      end
    else
    nil -> system_prompt
    end
  end

  @impl GenAI.ProviderBehaviour
  def format_tool(tool, state)
  def format_tool(tool, state) do
    {:ok, GenAI.Provider.Anthropic.ToolProtocol.tool(tool), state}
  end

  @impl GenAI.ProviderBehaviour
  def format_message(message, state)
  def format_message(message, state) do
    {:ok, GenAI.Provider.Anthropic.MessageProtocol.message(message), state}
  end

  @impl GenAI.ProviderBehaviour
  def run(state) do
    provider = __MODULE__
    with {:ok, provider_settings, state} <- GenAI.Thread.StateProtocol.provider_settings(state, provider),
         {:ok, settings, state} <- GenAI.Thread.StateProtocol.settings(state),
         {:ok, model, state} <- GenAI.Thread.StateProtocol.model(state),
         {:ok, model_settings, state} <- GenAI.Thread.StateProtocol.model_settings(state, model),
         {:ok, model_name} <- GenAI.ModelProtocol.model(model),
         {:ok, tools, state} <- GenAI.Thread.StateProtocol.tools(state, provider),
         {:ok, messages, state} <- GenAI.Thread.StateProtocol.messages(state, provider) do

      headers = headers(provider_settings)
      system_prompt = normalize_system_prompt(messages, tools, settings, model_settings, provider_settings)
      messages = normalize_messages(messages)

      body = %{
               model: model_name,
               messages: messages
             }
             |> with_setting(:max_tokens, settings, 4096)
             |> with_setting(:metadata, settings)
             |> with_setting_as(:stop_sequences, :stop, settings)
             |> with_setting(:temperature, settings)
             |> with_setting(:top_p, settings)
             |> with_setting(:top_k, settings)
             |> optional_field(:system, system_prompt)
      call = GenAI.Provider.api_call(:post, "#{@api_base}/v1/messages", headers, body)
      with {:ok, %Finch.Response{status: 200, body: body}} <- call,
           {:ok, json} <- Jason.decode(body, keys: :atoms),
          {:ok, output} <- chat_completion_from_json(json) do
        {:ok, output, state}
        
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
    provider_settings = Enum.filter(settings, fn {k,_} -> k in [:anthropic_version, :api_key, :api_org] end)
    chat(settings[:model], messages, tools, settings, provider_settings)
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

  def normalize_messages(messages, acc \\ [])

  def normalize_messages([%{role: :user} = a, %{role: :user} = b|t], acc) do
   a =%{a| content: a.content <> "\n\n<check-in>ack?</check-in>"}
    patch = %{
        role: :assistant,
        content: "ack",
      }
    normalize_messages(t, [b, patch, a | acc])
  end
  def normalize_messages([%{role: :assistant} = a, %{role: :assistant} = b|t], acc) do
    patch = %{
      role: :assistant,
      content: "continue.",
    }
    [b, patch, a]
    normalize_messages(t, [b, patch, a | acc])
  end
  def normalize_messages([h|t], acc), do: normalize_messages(t, [h|acc])
  def normalize_messages([], acc), do: Enum.reverse(acc)

  defp chat_completion_from_json(json) do
    with %{
           id: id,
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
        id: id,
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
      [%{type: "text", text: text}] ->
        # check for tool usage
        if String.contains?(text, "<function_calls>") do
          {text, f} = extract_function_calls(text)
          {:ok, %GenAI.Message.ToolCall{role: :assistant, content: text, tool_calls: f}}
        else
          {:ok, %GenAI.Message{role: :assistant, content: text}}
        end
    end
  end

  def extract_function_calls(input) do
    # Parse the HTML string
    {:ok, html_tree} = Floki.parse_document(input)

    # Extract the content inside the <function_calls> tag
    function_calls_content = Floki.find(html_tree, "function_calls")
                             |> Floki.raw_html()
                             |> String.replace("<function_calls>", "")
                             |> String.replace("</function_calls>", "")

    # Extract the content outside the <function_calls> tag
    outside_content = Floki.raw_html(html_tree)
                      |> String.replace("<function_calls>#{function_calls_content}</function_calls>", "")
    # Extract calls, assign unique identifiers.
    {:ok, html_tree} = Floki.parse_document(input)
    # Find the <invoke> tags
    invokes = Floki.find(html_tree, "invoke")
    # Transform each <invoke> tag
    calls = Enum.map(invokes, fn invoke ->
      # Find the <tool_name> and <parameters> tags and get their text content
      tool_name = Floki.find(invoke, "tool_name") |> Floki.text()
      parameters_json = Floki.find(invoke, "parameters") |> Floki.text()

      # Parse the parameters JSON string into a map
      parameters = Jason.decode!(parameters_json, keys: :atoms)

      # Create a new map with :tool_name and :parameters keys
      {:ok, short_uuid} = ShortUUID.encode(UUID.uuid4())
      %{
        id: "call_#{short_uuid}",
        type: "function",
        function: %{name: tool_name, arguments: parameters}
      }
    end)
    {outside_content, calls}
  end


  defmodule Models do


    def claude_opus() do
      %GenAI.Model{
        model: "claude-3-opus-20240229",
        provider: GenAI.Provider.Anthropic
      }
    end


    def claude_sonnet() do
      %GenAI.Model{
        model: "claude-3-sonnet-20240229",
        provider: GenAI.Provider.Anthropic
      }
    end

    def claude_sonnet_3_5() do
      %GenAI.Model{
        model: "claude-3-5-sonnet-20240620",
        provider: GenAI.Provider.Anthropic
      }
    end

    def claude_haiku() do
      %GenAI.Model{
        model: "claude-3-haiku-20240307",
        provider: GenAI.Provider.Anthropic
      }
    end

  end
end
