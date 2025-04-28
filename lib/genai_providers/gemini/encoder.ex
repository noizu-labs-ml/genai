defmodule GenAI.Provider.Gemini.Encoder do
  @base_url "https://generativelanguage.googleapis.com"
  use GenAI.Model.EncoderBehaviour
  
  
  #--------------------------------------------
  #
  #--------------------------------------------
  def api_key(settings, options \\ []) do
    search_scope = [
      options,
      settings[:model_settings],
      settings[:provider_settings],
      settings[:settings],
      settings[:config_settings],
    ]
    
    api_key = search_scope
              |> Enum.find_value(& &1[:api_key])
              
    unless api_key do
      raise GenAI.RequestError,
        message: "Gemini API key not found in settings or options"
    end
    {:ok, api_key}
  end
  
  #--------------------------------------------
  #
  #--------------------------------------------
  def endpoint(model, settings, session, context, options)
  def endpoint(model, settings, session ,_ ,options) do
    {:ok, model_name} = GenAI.ModelProtocol.name(model)
    {:ok, api_key} = api_key(settings, options)
    {:ok, {{:post, "#{@base_url}/v1beta/models/#{model_name}:generateContent?key=#{api_key}"}, session}}
  end
  
  #--------------------------------------------
  #
  #--------------------------------------------
  def headers(model, settings, session, context, options) do
    headers = [{"content-type", "application/json"}]
    {:ok, {headers, session}}
  end
  
  def default_hyper_params(model, settings, session, context, options)
  def default_hyper_params(model, settings, session, context, options) do
    x = [
      hyper_param(name: :max_tokens, as: :max_output_tokens),
      hyper_param(name: :stop_sequence, as: :stop_sequences),
      hyper_param(name: :temperature),
      hyper_param(name: :top_k),
      hyper_param(name: :top_p),
    ]
    {:ok, x}
  end
  
  # ---------------------------------
  # request_body/7
  # ---------------------------------
  # @todo support response modalities
  @doc "Prepare request body to be passed to inference call."
  def request_body(model, messages, tools, settings, session, context, options)
  def request_body(model, messages, tools, settings, session, context, options) do
    with {:ok, model_name} <- GenAI.ModelProtocol.name(model),
         {:ok, params} <- hyper_params(model, settings, session, context, options) do
      
      tool_declaration =
        with [_|_] <- tools do
          [%{function_declarations: tools}]
        end
      
      body =
        %{contents: messages}
        |> optional_field(:generation_config, generation_config(params, model, settings))
        |> optional_field(:safety_settings, safety_settings(settings))
        |> optional_field(:tools, tool_declaration)
      {:ok, {body, session}}
    end
  end
  
  # -------------------------
  #
  # -------------------------
  defp generation_config(params, model, settings) do
    config = GenAI.Model.Encoder.DefaultProvider.apply_hyper_params_and_adjust(__MODULE__, %{}, params, model, settings)
    unless config == %{}, do: config
  end
  
  # -------------------------
  #
  # -------------------------
  defp safety_settings(%{safety_settings: nil}), do: nil
  defp safety_settings(%{safety_settings: []}), do: nil
  defp safety_settings(%{safety_settings: x}) when is_list(x) or is_map(x) do
    Enum.map(x, fn {category, threshold} -> %{category: category, threshold: threshold} end )
  end

  
  #--------------------------------------------
  #
  #--------------------------------------------
  # @todo normalize_messages - inject space between like roles
  
  #--------------------------------------------
  #
  #--------------------------------------------
  
  
  
  def completion_response(json, model, settings, session, context, options)
  
  def completion_response(json, model, settings, session, context, options) do
    with {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         {:ok, model_name} <- GenAI.ModelProtocol.name(model),
         %{candidates: candidates} <- json do

      id = json[:id]
      choices =
        candidates
        |> Enum.map(& completion_choices(id, &1, model, settings, session, context, options))
        |> Enum.map(fn {:ok, x} -> x end)
        
      completion = GenAI.ChatCompletion.from_json(
        id: id,
        model: model_name,
        provider: provider,
        choices: choices,
        usage: GenAI.ChatCompletion.Usage.new([]),
        details: json
      )
      {:ok, completion}
    end
  end
  
  def completion_choices(id, json, model, settings, session, context, options)
  
  def completion_choices(
        id,
        json = %{index: index, content: message_json, finishReason: finish_reason},
        model,
        settings,
        session,
        context,
        options
      ) do
      
    with {:ok, message} <-
           completion_choice(id, message_json, model, settings, session, context, options) do
      choice = GenAI.ChatCompletion.Choice.new(
        id: json[:id],
        index: index,
        message: message,
        finish_reason: finish_reason && String.downcase(finish_reason)
      )
      {:ok, choice}
    end
  end
  
  def completion_choice(id, json, model, settings, session, context, options)
  
  def completion_choice(
        _,
        json = %{
          role: "model",
          parts: contents
        },
        _,
        _,
        _,
        _,
        _
      ) do
    
    content = completion_message(json)
    tool_calls = Enum.filter(content, & &1.__struct__ == GenAI.Message.Content.ToolUseContent)
    
    # @TODO the protocol must scan content for tool content and seperate it out
    # when preping for gemini
    id = json[:id]
    
    msg = cond do
      tool_calls == [] ->
        GenAI.Message.new(id: id, role: :assistant, content: content)
      :else ->
        GenAI.Message.ToolUsage.new(id: id, role: :assistant, content: content, tool_calls: [])
    end
    {:ok, msg}
  end
  
  defp gen_unique_call_id do
    {:ok, short_uuid} = ShortUUID.encode(UUID.uuid4())
    "call_#{short_uuid}"
  end
  
  def completion_message(%{parts: content}) when is_bitstring(content) do
    Enum.map([content], &completion_content/1)
  end
  def completion_message(%{parts: content}) when is_list(content) do
    Enum.map(content, &completion_content/1)
  end
  
  def completion_content(json)

  def completion_content(%{functionCall: %{name: tool_name, args: arguments}} = json) do
    id = json[:id] || gen_unique_call_id()
    %GenAI.Message.Content.ToolUseContent{
      id: id,
      tool_name: tool_name,
      arguments: arguments
    }
  end
  
  def completion_content(%{text: text} = json)  do
    %GenAI.Message.Content.TextContent{
      system: false,
      type: :response,
      text: text,
    }
  end
  
  @image_mime_types [
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "image/svg+xml",
  ]
  
  def completion_content(
        %{
          inline_data: %{
            mime_type: mime_type,
            data: base64
          }
        } = json) when mime_type in @image_mime_types  do
    
    media_types = %{
      "image/jpeg" => :jpeg,
      "image/png" => :png,
      "image/gif" => :gif,
      "image/webp" => :webp,
      "image/svg+xml" => :svg,
    }
    GenAI.Message.Content.ImageContent.new(
      {:base64, base64},
      source: :gemini,
      type: media_types[mime_type]
    )
  end


end