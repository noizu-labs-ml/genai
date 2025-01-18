#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defprotocol GenAI.Session.NodeProtocol do
    @doc """
    Process node and proceed to next step.
    
  """
    #TODO add specs
    
    @doc """
    Return the type of node. Used for validating input requsts and orchestrating state manipulation by providers.
    """
    def node_type(graph_node)
    
    @doc """
    Apply node, update state if expired, run inference/logic for special nodes, etc. if cached value expired. Apply directives, etc.
    """
    def process_node(graph_node, scope, context, options)
    
    
    @doc """
    Gather input values to be consumed inside of process_node method.
    """
    def update_state_input(graph_node, scope, context, options)
    
    
    
    
    @doc """
    Update state for node and link.
    Use directives if artifacts have been modified.
    This will raise if fingerprint unchanged for data security.
    """
    def update_state(graph_node, scope, context, options)
    
    
    
    
    @doc """
    Return directive(s) for setting tools/messages/settings/artifacts for node.
    Only executed by default handler if fingerprint change indicates values will result in new values.
    Directives with unchanged fingerprint will not be updated.
    """
    def directives(graph_node, input, finger_print_key, scope, context, options)
    
    
    @doc """
    Prepare finger_print_key digest message as a (map) used to generate your finger_print digest. For static nodes with no input we simply reference node id.
    
    If a node is dependent on a data generator and contents of a dynamic system prompt the digest map, and ttl value then you
    should include the data generator value finger_print, the system_prompt message finger_print (which in indicates if it has changed.)
    and ttl element.
    e.g
    ```elixir
    %{
      id: self.id,
      data_record: data_record.finder_print,
      system_prompt: message_by_handle!(:dynamic_system_prompt).finger_print,
      ttl: div(System.time(:second), 3600)
    }
    ```
    
    You will generally want to override this method for dynamic nodes,
    for convenience you can generally just specify pass options to derive to control values used.
    and input values will be automatically injected into the fingerprint map unless wrapped in request with ignore_finger_print modifier.
    manually setting input values with out this specifier (even if initially set on request) will result in the ignore flag being cleared.
    
    ```elixir
        @derive GenAI.Session.NodeProtocol [
            provider: GenAI.Session.NodeProtocol.DefaultProvider,
            # Inject values from state into input arguments with out need to manually fetch.
            # Values are passed to directives by default process_node method.
            input: %{
                data_set_foo: data_set(name: :foo, count: 5), # grab from generator
                data_set_bar: data_set(name: :bar, count: 3), # grab from generator
                memories: memory_injector(),
                user_local: no_finger_print(stack(:user_local)), # request an input but don't automatically add to fingerprint list.
            },
            finger_print: %{
                data_set_foo: input(:data_set_foo), # this would be auto injected as it's in input list.
                data_set_bar: input(:data_set_bar), # a passed in input map value (values from input field plut modifiers are made available here.
                system_prompt: message_by_handle(:dynamic_system_prompt),
                memories: input(:memories),
                temperature: setting(:temperature), # used if for example in a grid loop.
                ttl: ttl(3600),
                user_name: stack(:user_name),
                dynamic: dynamic_key(), # always generate new fingerprint regardless of any other changes.
            }
        ]
    ```
    """
    def finger_print_key(graph_node, input, default_key, scope, context, options)
    
    
    
    @doc """
    Calculate Cache Finger print for node. Used to determine if node has changed and needs to be reprocessed.
    The default implementation should be fine for most cases but you can override if needed.
    """
    def finger_print(graph_node, finger_print_key, scope, context, options)
    
    #==================================
    # Meta Data Feed
    #==================================
    def graph_node_protocol_options(graph_node, context, options)
    def __derive_graph_node_protocol_options__(graph_node)
    
end

defimpl GenAI.Session.NodeProtocol, for: Any do
    defmacro __deriving__(module, _struct, options) do
        options = Macro.escape(options)
        quote do
            defimpl GenAI.Session.NodeProtocol, for: unquote(module) do
                
                @provider unquote(options[:provider]) || GenAI.Session.NodeProtocol.DefaultProvider
                @input_directives unquote(options)[:input] || %{}
                @finger_print unquote(options)[:finger_print] || %{}
                @graph_node_protocol_options %{
                    provider: @provider,
                    input: @input_directives,
                    finger_print: @finger_print
                }
                
                defdelegate node_type(graph_node), to: @provider
                defdelegate process_node(graph_node, scope, context, options), to: @provider
                defdelegate update_state(graph_node, scope, context, options), to: @provider
                defdelegate graph_node_protocol_options(graph_node, context, options), to: @provider
                def __derive_graph_node_protocol_options__(graph_node) do
                    @graph_node_protocol_options
                end
                defdelegate update_state_input(graph_node, scope, context, options), to: @provider
                defdelegate finger_print(graph_node, finger_print_key, scope, context, options), to: @provider
                defdelegate finger_print_key(graph_node, input, default_key, scope, context, options), to: @provider
                defdelegate directives(graph_node, input, finger_print_key, scope, context, options), to: @provider
            
            end
        end
    end
end

defmodule GenAI.Session.NodeProtocol.DefaultProvider do
    require GenAI.Session.Node.Records
    alias GenAI.Session.Node.Records, as: Node
    require GenAI.Graph.Link.Records
    alias GenAI.Graph.Link.Records, as: Link
    require GenAI.Session.Records
    alias GenAI.Session.Records, as: S
    
    def graph_node_protocol_options(%{__struct__: module} = graph_node, context, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :graph_node_protocol_options, 3) do
            module.graph_node_protocol_options(graph_node, context, options)
        else
            GenAI.Session.NodeProtocol.__derive_graph_node_protocol_options__(graph_node)
        end
    end
    
    #-----------------------------------------------
    # node_type
    #-----------------------------------------------
    @doc """
    Return node type (used for input validation.
    """
    def node_type(%{__struct__: module} = graph_node) do
        if Code.ensure_loaded?(module) and function_exported?(module, :node_type, 1) do
            module.node_type(graph_node)
        else
            do_node_type(graph_node)
        end
    end
    
    def do_node_type(%{__struct__: module}) do
        module
    end
    
    #-----------------------------------------------
    # process_node
    #-----------------------------------------------
    @doc """
    Apply/process a node. check/update fingerprint and add any appropriate directives to state.
    """
    def process_node(%{__struct__: module} = graph_node, scope, context, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :process_node, 4) do
            module.process_node(graph_node, scope, context, options)
        else
            do_process_node(graph_node, scope, context, options)
        end
    end
    
    
    def do_process_node(graph_node, scope, context, options)
    def do_process_node(
            %{__struct__: module} = graph_node,
            Node.scope(
                graph_node: original_graph_node,
                graph_link: graph_link,
                graph_container: graph_container,
                session_state: session_state,
                session_runtime: session_runtime
            ), context, options) do
      # Update state,
      # Emit Telemetry/Monitors
      # Populate effective state in state under id.
        updated_state = session_state
        # TODO - outbound links protocol method needed.
        with {:ok, links} <-
               GenAI.Graph.NodeProtocol.outbound_links(graph_node, graph_container, expand: true) do
          
          
          # Single node support only
            links = links
                    |> Enum.map(fn {socket, links} -> links end)
                    |> List.flatten()
            case links do
                [] -> Node.process_end(exit_on: {graph_node, :no_links}, update: Node.process_update(session_state: updated_state))
                [link] ->
                    Node.process_next(
                        link: link,
                        update: Node.process_update(session_state: updated_state))
            end
        end
    end
    
    #-----------------------------------------------
    # update_state
    #-----------------------------------------------
    def update_state(%{__struct__: module} = graph_node, scope, context, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :process_node, 4) do
            module.update_state(graph_node, scope, context, options)
        else
            do_update_state(graph_node, scope, context, options)
        end
    end
    def do_update_state(graph_node, scope, context, options) do
    
    end
    
    #-----------------------------------------------
    # update_state_input
    #-----------------------------------------------
    def update_state_input(%{__struct__: module} = graph_node, scope, context, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :update_state_input, 4) do
            module.update_state_input(graph_node, scope, context, options)
        else
            do_update_state_input(graph_node, scope, context, options)
        end
    end
    
    
    def do_update_state_input(graph_node, scope = Node.scope(), context, options) do
        with config = %{input: x} <- GenAI.Session.NodeProtocol.graph_node_protocol_options(graph_node, context, options) do
            GenAI.Session.Node.Input.expand_inputs(config.input, scope, context, options)
        end
    end
    
    #-----------------------------------------------
    # node_directives
    #-----------------------------------------------
    def node_directives(%{__struct__: module} = graph_node, input, finger_print_key, scope, context, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :update_state_input, 6) do
            module.directives(graph_node, input, finger_print_key, scope, context, options)
        else
            do_node_directives(graph_node, input, finger_print_key, scope, context, options)
        end
    end
    def do_node_directives(graph_node, input, finger_print_key, scope, context, options), do: nil
    
    #-----------------------------------------------
    # finger_print_key
    #-----------------------------------------------
    def finger_print_key(%{__struct__: module} = graph_node, input, default_key, scope, context, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :finger_print_key, 6) do
            module.finger_print_key(graph_node, input, default_key, scope, context, options)
        else
            do_finger_print_key(graph_node, input, default_key, scope, context, options)
        end
    end
    def do_finger_print_key(graph_node, input, default_key, scope, context, options), do: nil
    
    #-----------------------------------------------
    # finger_print
    #-----------------------------------------------
    def finger_print(%{__struct__: module} = graph_node, finger_print_key, scope, context, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :finger_print, 5) do
            module.finger_print(graph_node, finger_print_key, scope, context, options)
        else
            do_finger_print(graph_node, finger_print_key, scope, context, options)
        end
    end
    
    def do_finger_print(graph_node, finger_print_key, scope, context, options) do
        nil
    end
    
    
    #===========================================================================
    # Helpers
    #===========================================================================

    
    
end






defmodule GenAI.Session.NodeProtocol.Runner do
    require GenAI.Session.Node.Records
    alias GenAI.Session.Node.Records, as: Node
    require GenAI.Graph.Link.Records
    alias GenAI.Graph.Link.Records, as: Link
    
    
    def apply_process_update(scope, updates, context, options)
    def apply_process_update(
            Node.scope(
                graph_node: graph_node,
                graph_link: graph_link,
                graph_container: graph_container,
                session_state: session_state,
                session_runtime: session_runtime
            ),
            Node.process_update(
                graph_node: graph_node_changes,
                graph_link: graph_link_changes,
                graph_container: graph_container_changes,
                session_state: session_state_changes,
                session_runtime: session_runtime_changes
            ),
            _context,
            _options
        ) do
        
        # changes will eventually be monads that mutate state thus we use two data types process_update and scope
        r = Node.process_update(
            graph_node:  graph_node_changes || graph_node,
            graph_link: graph_link_changes || graph_link,
            graph_container: graph_container_changes || graph_container,
            session_state: session_state_changes || session_state,
            session_runtime: session_runtime_changes || session_runtime
        )
        {:ok, r}
      
      
      # @TODO - Implement Change Manager
      
      #        # Future Work
      #        if not is_nil(graph_node_changes) and graph_node != graph_node_changes do
      #          raise GenAI.Flow.Exception, "Graph Node Update Not Currently Supported - use state object for node state changes."
      #        end
      #        if not is_nil(graph_link_changes) and graph_link != graph_link_changes do
      #          raise GenAI.Flow.Exception, "Graph Link Update Not Currently Supported - use state object for link state changes."
      #        end
      #        if not is_nil(graph_container_changes) and graph_container != graph_container_changes do
      #          raise GenAI.Flow.Exception, "Graph Container Update Not Currently Supported - use state object for container state changes."
      #        end
      
      #with {:ok, updated_session_state} <- GenAI.Session.UpdateProtocol.apply_changes(session_state, session_state_changes),
      #     {:ok, updated_session_runtime} <- GenAI.Session.UpdateProtocol.apply_changes(session_runtime, session_runtime_changes) do
      #  {:ok, {graph_node, graph_link, graph_container, update_session_state, update_session_runtime}}
      #end
    
    end
    
    
    def do_process_node(graph_node, scope, context, options)
    def do_process_node(
            graph_node,
            scope = Node.scope(
                graph_node: original_graph_node,
                graph_link: graph_link,
                graph_container: graph_container,
                session_state: session_state,
                session_runtime: session_runtime
            ),
            context,
            options
        ) do
        
        case GenAI.Session.NodeProtocol.process_node(graph_node, scope, context, options)
          do
            Node.process_next(link: next_graph_link, update: processing_update) ->
                with {:ok, params = Node.process_update()} <-
                       apply_process_update(
                           Node.scope(scope, graph_node: graph_node),
                           processing_update,
                           context,
                           options
                       ),
                     Node.process_update(
                         graph_node: graph_node,
                         graph_link: graph_link,
                         graph_container: graph_container,
                         session_state: session_state,
                         session_runtime: session_runtime
                     ) <- params,
                     {:ok, target = Link.connector()} <- GenAI.Graph.Link.target_connector(next_graph_link),
                     #  @ODO should be node protocol
                     {:ok, next_graph_node} <- GenAI.Graph.node(graph_container, target) do
                    do_process_node(
                        next_graph_node,
                        Node.scope(scope,
                            graph_node: next_graph_node,
                            graph_link: next_graph_link,
                        ),
                        context,
                        options)
                end
            
            return = Node.process_end(exit_on: exit_on, update: processing_update) ->
                with {:ok, params = Node.process_update()}
                     <- apply_process_update(
                    Node.scope(scope, graph_node: graph_node),
                    processing_update,
                    context,
                    options
                )  do
                    Node.process_end(return, update: params)
                end
            
            Node.process_yield(yield_for: yield_for) ->
                raise GenAI.Flow.Exception, "Yield Not Yet Implemented: #{inspect yield_for}"
            return = Node.process_error(error: error, update: processing_update) ->
                with {:ok, params = Node.process_update()} <- apply_process_update(
                    Node.scope(scope, graph_node: graph_node),
                    processing_update,
                    context,
                    options
                )  do
                    Node.process_error(return, update: params)
                end
        end
    end
end