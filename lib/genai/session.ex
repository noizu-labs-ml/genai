#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defmodule GenAI.Session.Runtime do
    @moduledoc false
    @vsn 1.0
    defstruct [
        command: :default,
        config: [],
        data: %{},
        monitors: %{},
        meta: %{},
        vsn: @vsn
    ]
    
    def new(options \\ nil)
    def new(options) do
        %__MODULE__{
            command: options[:command] || :default,
        }
    end
    
    
    defp prepare_command(command, context, options)
    defp prepare_command(command, _context, _options) when is_atom(command), do: {command, []}
    defp prepare_command({command, config}, _, _) when is_atom(command), do: {command, config}
    
    def command(runtime, command, context, options \\ nil)
    def command(runtime, command, context, options) when is_atom(command) do
        command(runtime, prepare_command(command, context, options), context, options)
    end
    def command(runtime, {command, config}, context, options) do
        {command, config} = prepare_command({command, config}, context, options)
        # deal with merging config
        x = %__MODULE__{runtime|
            command: command,
            config: config,
            monitors: %{},
            data: %{},
            meta: %{}
        }
        {:ok, x}
    end

end

defmodule GenAI.Session do
    @moduledoc false
    @vsn 1.0
    require GenAI.Session.Node.Records
    alias GenAI.Session.Node.Records, as: Node
    
    defstruct [
        state: nil,
        graph: nil,
        runtime: nil,
        vsn: @vsn
    ]
    
    def new(options \\ nil)
    def new(options) do
        graph = GenAI.Graph.new(options[:graph])
        state = GenAI.Session.State.new(options[:state])
        runtime = GenAI.Session.Runtime.new(options[:runtime])
        
        %__MODULE__{
            state: state,
            graph: graph,
            runtime: runtime,
            vsn: @vsn
        }
    end
    
    #-------------------------------------------
    # Session Behavior
    #---------------------------------------------
    require Logger
    
    defp append_node(context, node, options \\ nil)
    defp append_node(context, node, options) do
        update_in(context, [Access.key(:graph)], & GenAI.Graph.attach_node(&1, node, options))
    end
    
    #-------------------------------------
    # with_model/2
    #-------------------------------------
    @doc """
    Specify a specific model or model picker.
    
    This function allows you to define the model to be used for inference.
    You can either provide a specific model, like `Model.smartest()`, or a model picker function that dynamically selects
    the best model based on the context and available providers.
    
    Examples:
    * `Model.smartest()` - This will select the "smartest" available model at inference time, based on factors
      like performance and capabilities.
    * `Model.cheapest(params: :best_effort)` - This will select the cheapest available model that can handle the
      given parameters and context size.
    * `CustomProvider.custom_model` - This allows you to use a custom model from a user-defined provider.
    """
    def with_model(context, model) do
        if GenAI.Session.NodeProtocol.impl_for(model) && GenAI.Model == GenAI.Session.NodeProtocol.node_type(model) do
            {:ok, n} = GenAI.Graph.NodeProtocol.with_id(model)
            context
            |> append_node(n)
        else
            cond do
                is_struct(model) ->
                    raise GenAI.Graph.Exception, "With Model Argument Must Implement GenAI.Session.NodeProtocol and report node_type as GenAI.Model: #{model.__struct__}"
                :else ->
                    raise GenAI.Graph.Exception, "With Model Argument Must Implement GenAI.Session.NodeProtocol and report node_type GenAI.Model: #{inspect model}"
            end
        end
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    
    def with_tool(context, tool) do
        if GenAI.Session.NodeProtocol.impl_for(tool) && GenAI.Tool == GenAI.Session.NodeProtocol.node_type(tool) do
            {:ok, n} = GenAI.Graph.NodeProtocol.with_id(tool)
            context
            |> append_node(n)
        else
            cond do
                is_struct(tool) ->
                    raise GenAI.Graph.Exception, "With Tool Argument Must Implement GenAI.Session.NodeProtocol and report node_type as GenAI.Tool: #{tool.__struct__}"
                :else ->
                    raise GenAI.Graph.Exception, "With Tool Argument Must Implement GenAI.Session.NodeProtocol and report node_type GenAI.Tool: #{inspect tool}"
            end
        end
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    def with_tools(context, tools) do
        Enum.reduce(tools, context, fn(tool, context) ->
            with_tool(context, tool)
        end)
        context
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    
    @doc """
    Specify an API key for a provider.
    """
    def with_api_key(context, provider, api_key) do
        n = %GenAI.Setting.ProviderSetting{
            id: UUID.uuid4(),
            provider: provider,
            setting: :api_key,
            value: api_key
        }
        context
        |> append_node(n)
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    
    @doc """
    Specify an API org for a provider.
    """
    def with_api_org(context, provider, api_org) do
        n = %GenAI.Setting.ProviderSetting{
            id: UUID.uuid4(),
            provider: provider,
            setting: :api_org,
            value: api_org
        }
        context
        |> append_node(n)
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    
    @doc """
    Set a hyperparameter option.
    
    Some options are model-specific. The value can be a literal or a picker function that dynamically determines
    the best value based on the context and model.
    
    Examples:
    * `Parameter.required(name, value)` - This sets a required parameter with the specified name and value.
    * `Gemini.best_temperature_for(:chain_of_thought)` - This uses a picker function to determine the best temperature
       for the Gemini provider when using the "chain of thought" prompting technique.
    """
    def with_setting(context, setting, value) do
        n = %GenAI.Setting{
            id: UUID.uuid4(),
            setting: setting,
            value: value
        }
        context
        |> append_node(n)
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    def with_setting(context, setting) do
        if GenAI.Session.NodeProtocol.impl_for(setting) && GenAI.Setting == GenAI.Session.NodeProtocol.node_type(setting) do
            {:ok, n} = GenAI.Graph.NodeProtocol.with_id(setting)
            context
            |> append_node(n)
        else
            cond do
                is_struct(setting) ->
                    raise GenAI.Graph.Exception, "With Setting Argument Must Implement GenAI.Session.NodeProtocol and report node_type as GenAI.Setting: #{setting.__struct__}"
                :else ->
                    raise GenAI.Graph.Exception, "With Setting Argument Must Implement GenAI.Session.NodeProtocol and report node_type GenAI.Setting: #{inspect setting}"
            end
        end
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    def with_settings(context, settings) do
        Enum.reduce(settings, context,
            fn
                ({setting, value}, context) -> with_setting(context, setting, value)
                (value, context) when is_struct(value) -> with_setting(context, value)
            end
        )
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    def with_safety_setting(context, category, threshold) do
        n = %GenAI.Setting.SafetySetting{
            id: UUID.uuid4(),
            category: category,
            threshold: threshold
        }
        context
        |> append_node(n)
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    def with_safety_setting(context, safety_setting) do
        if GenAI.Session.NodeProtocol.impl_for(safety_setting) && GenAI.Setting == GenAI.Session.NodeProtocol.node_type(safety_setting) do
            {:ok, n} = GenAI.Graph.NodeProtocol.with_id(safety_setting)
            context
            |> append_node(n)
        else
            cond do
                is_struct(safety_setting) ->
                    raise GenAI.Graph.Exception, "With Safety Setting Argument Must Implement GenAI.Session.NodeProtocol and report node_type as GenAI.Setting: #{safety_setting.__struct__}"
                :else ->
                    raise GenAI.Graph.Exception, "With Safety Setting Argument Must Implement GenAI.Session.NodeProtocol and report node_type GenAI.Setting: #{inspect safety_setting}"
            end
        end
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    def with_safety_settings(context, safety_settings) do
        Enum.reduce(safety_settings, context,
            fn
                ({category, threshold}, context) -> with_safety_setting(context, category, threshold)
                (safety_setting, context) when is_struct(safety_setting) -> with_safety_setting(context, safety_setting)
            end
        )
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    
    @doc """
    Add a message to the conversation.
    """
    def with_message(context, message, options \\ nil)
    def with_message(context, message, _) do
        if GenAI.Session.NodeProtocol.impl_for(message) && GenAI.Message == GenAI.Session.NodeProtocol.node_type(message) do
            {:ok, n} = GenAI.Graph.NodeProtocol.with_id(message)
            context
            |> append_node(n)
        else
            cond do
                is_struct(message) ->
                    raise GenAI.Graph.Exception, "With Message Argument Must Implement GenAI.Session.NodeProtocol and report node_type as GenAI.Message: #{message.__struct__}"
                :else ->
                    raise GenAI.Graph.Exception, "With Message Argument Must Implement GenAI.Session.NodeProtocol and report node_type GenAI.Message: #{inspect message}"
            end
        end
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    @doc """
    Add a list of messages to the conversation.
    """
    def with_messages(context, messages, options)
    def with_messages(context, messages, options) do
        Enum.reduce(messages, context, fn(message, context) ->
            with_message(context, message, options)
        end)
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    @doc """
    specify/override default stream handler
    """
    def with_stream_handler(context, handler, options)
    def with_stream_handler(context, _, _) do
        Logger.info("nyi")
        context
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    @doc """
    Start inference using a streaming handler.
    
    If the selected model does not support streaming, the handler will be called with the final inference result.
    """
    def stream(session, context, options)
    def stream(_,_,_) do
        {:ok, :pending}
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    @doc """
    Run inference.
    
    This function performs the following steps:
    * Picks the appropriate model and hyperparameters based on the provided context and settings.
    * Performs any necessary pre-processing, such as RAG (Retrieval-Augmented Generation) or message consolidation.
    * Runs inference on the selected model with the prepared input.
    * Returns the inference result.
    """
    def run(session, context, options)
    def run(_,_,_) do
      
      
      
      #    with {:prepare_state, {:ok, state}} <-
      #           GenAi.Graph.NodeProtocol.apply(context.graph, context.state)
      #           |> label(:prepare_state),
      #         {:effective_model, {:ok, model, state}} <-
      #           GenAI.Thread.StateProtocol.model(state)
      #           |> label(:effective_model) do
      #      GenAI.ProviderBehaviour.run(model, state)
      #    end
      # GenAI.Thread.NodeProtocol.process_node(context.flow, nil, nil, context.state, options)
        {:ok, :pending}
    end
    
    #-------------------------------------
    #
    #-------------------------------------
    @doc """
    Execute a command, such as run prompt fine tuner, dynamic prompt etc.
    # Options
    - report: return a report of the command execution (entire effective conversation with extended timing/loop details.
    - thread: return full thread along with most recent reply, useful for investigating exact dynamic messages generated in flow
    """
    def execute(session, command, context, options) do
        context = context || Noizu.Context.system()
        with {:ok, runtime} <-
               # Set Runtime Mode
               GenAI.Session.Runtime.command(session.runtime, command, context, options),
             {:ok, session_state} <-
               # Refresh state (clear any ephemeral values, etc. for rerun as specified by runtime object
               # set seeds, clear monitor cache, etc.
               GenAI.Session.State.initialize(session.state, runtime, context, options),
             {:ok, {session_state, runtime}} <-
               # Setup telemetry agents, etc.
               GenAI.Session.State.monitor(session_state, runtime, context, options) do
            with x <- GenAI.Session.NodeProtocol.process_node(
                session.graph,
                Node.scope(
                    graph_node: session.graph,
                    graph_link: nil,
                    graph_container: nil,
                    session_state: session_state,
                    session_runtime: runtime
                ),
                context,
                options) do
              # TODO apply updates, return completion (if any) and session and generated report from monitor agent
                {:ok, :pending2}
            end
        end
      
      # Spawn Monitor Agent
      # Register Callbacks to Monitor Agent
      # Process session
      # Strip runtime flags from execute
      # Get metrics from monitor
    
    end

end
