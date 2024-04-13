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

  defp tool_system_prompt(nil), do: nil
  defp tool_system_prompt([]), do: nil
  defp tool_system_prompt(tools) do
    tools = Enum.map(tools, &GenAI.Provider.Anthropic.ToolProtocol.tool/1)
            |> Jason.encode!()
            |> Jason.decode!()
    tools = %{tools: tools}
    with {:ok, yaml} <- Ymlr.document(tools) do
      yaml = String.trim_leading(yaml, "---\n")
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
    end
  end

  def chat(messages, tools, settings) do
    headers = headers(settings)
    system_prompt = settings[:system_prompt]

    # todo inject stop sequence </function_calls>
    tool_usage_prompt = tool_system_prompt(tools)

    system_prompt = cond do
      tool_usage_prompt ->
        if system_prompt do
          "#{system_prompt}\n-----\n#{tool_usage_prompt}"
        else
          tool_usage_prompt
        end
      :else -> system_prompt
    end

    body = %{}
           |> with_required_setting(:model, settings)
           |> with_setting(:max_tokens, settings, 4096)
           |> with_setting(:metadata, settings)
           |> with_setting_as(:stop_sequences, :stop, settings)
           |> with_setting(:temperature, settings)
           |> with_setting(:top_p, settings)
           |> with_setting(:top_k, settings)
           |> optional_field(:system, system_prompt)
           |> Map.put(:messages,
                Enum.map(messages, &GenAI.Provider.Anthropic.MessageProtocol.message/1)
                |> normalize_messages()
              )
    call = GenAI.Provider.api_call(:post, "#{@api_base}/v1/messages", headers, body)
    # |> IO.inspect(limit: :infinity, printable_limit: :infinity)
    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      chat_completion_from_json(json)
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


    def claude_haiku() do
      %GenAI.Model{
        model: "claude-3-haiku-20240307",
        provider: GenAI.Provider.Anthropic
      }
    end




  end
end
