defmodule GenAI do
    
    @doc """
    Creates a new chat context.
    """
    def chat(context_type \\ :default, options \\ nil)
    def chat(:default, options), do: GenAI.Session.new(options)
    def chat(:standard, options), do: GenAI.Session.new(options)
    
    # Delegate function calls to the GenAI.SessionProtocol implementation for the current context.
    
    @doc """
    Set model or model selector constraint for inference.
    """
    defdelegate with_model(context, model), to: GenAI.SessionProtocol
    
    @doc """
    Set tool for inference.
    """
    defdelegate with_tool(context, tool), to: GenAI.SessionProtocol
    
    @doc """
    Set tools for inference.
    """
    defdelegate with_tools(context, tools), to: GenAI.SessionProtocol
    
#    @doc """
#    Specify API Provider or Provider constraint
#    """
#    defdelegate with_api_provider(context, provider), to: GenAI.SessionProtocol
    
    @doc """
    Set API Key or API Key constraint for inference.
    @todo we will need per model keys for ollam and hugging face.
    """
    defdelegate with_api_key(context, provider, api_key), to: GenAI.SessionProtocol
    
    @doc """
    Set API Org or API Org constraint for inference.
    """
    defdelegate with_api_org(context, provider, api_org), to: GenAI.SessionProtocol
    
    @doc """
    Set Inference setting.
    """
    defdelegate with_setting(context, setting, value), to: GenAI.SessionProtocol
    
    @doc """
    Set setting or setting selector constraint for inference.
    """
    defdelegate with_setting(context, setting_object), to: GenAI.SessionProtocol
    
    @doc """
    Set settings setting selector constraints for inference.
    """
    defdelegate with_settings(context, settings), to: GenAI.SessionProtocol
    
    @doc """
    Set safety setting for inference.
    @note - only fully supported by Gemini. backwards compatibility can be enabled via prompting but will be less reliable.
    """
    defdelegate with_safety_setting(context, safety_setting, threshold), to: GenAI.SessionProtocol
    defdelegate with_safety_settings(context, safety_settings), to: GenAI.SessionProtocol
    
#    @doc """
#    Set the thread ID.
#    """
#    defdelegate with_thread_id(context, thread_id), to: GenAI.SessionProtocol
    
    @doc """
    Append message to thread.
    @note Message may be dynamic/generated.
    """
    defdelegate with_message(context, message, options \\ nil), to: GenAI.SessionProtocol
    
    @doc """
    Append messages to thread.
    @note Messages may be dynamic/generated.
    """
    defdelegate with_messages(context, messages, options \\ nil), to: GenAI.SessionProtocol
    
    @doc """
    Override streaming handler module.
    """
    defdelegate with_stream_handler(context, handler, options \\ nil), to: GenAI.SessionProtocol
    
    @doc """
    Run inference. Returning update chat completion and updated thread state.
    """
    defdelegate run(context, options \\ nil), to: GenAI.SessionProtocol
    
    @doc """
    Run inference in streaming mode, interstitial messages (dynamics) if any will sent to the stream handler using the interstitial handle
    """
    defdelegate stream(context, options \\ nil), to: GenAI.SessionProtocol
    
    @doc """
    Execute command.
    
    # Notes
    Used, for example, to retrieve full report of a thread with an optimization loop or data loop command.
    Under usual processing not final/accepted grid search loops are not returned in response and a linear thread is returned. Execute mode however will return a graph of all runs, or meta data based on options, and grid search configuration.
    """
    defdelegate execute(context, command \\ :thread, options \\ nil), to: GenAI.SessionProtocol

end
