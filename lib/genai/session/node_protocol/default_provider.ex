defmodule GenAI.Session.NodeProtocol.DefaultProvider do
    require GenAI.Session.NodeProtocol.Records
    alias GenAI.Session.NodeProtocol.Records, as: Node
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
        # What occurs durring process_node?
        # 1. We update state (if any)
        #    When is state updated? this doesn't occur in most nodes other than loop entry nodes, nodes that fetch data or loop iterator content.
        # 2. we apply any directives/messages.
        #    We will keep directives and messages separate.
        # 3. We check if we have any outbound links.
        # 4. We process the next node or end
        # 5. telemetry?
        process_node_response(graph_node, graph_container, Node.process_update())
    end
    
    def process_node_response(graph_node, graph_container, update) do
        with {:ok, links} <- GenAI.Graph.NodeProtocol.outbound_links(
            graph_node,
            graph_container,
            expand: true
        ) do
            links = links
                    |> Enum.map(fn {socket, links} -> links end)
                    |> List.flatten()
            # Single node support only
            case links do
                [] ->
                    Node.process_end(
                          exit_on: {graph_node, :no_links},
                        update: update
                    )
                [link] ->
                    Node.process_next(
                        link: link,
                        update: update
                    )
            end
        end
    end
    
    #-----------------------------------------------
    # new_selector/3
    #-----------------------------------------------
    def new_selector(target, value, options \\ nil)
    def new_selector(target, value, _) do
        ts = System.system_time(:nanosecond)
        S.selector(
            for: target,
            value: value,
            inserted_at: ts,
            updated_at: ts
        )
    end
    
    #-----------------------------------------------
    # new_directive/5
    #-----------------------------------------------
    def new_directive(name, for_node, entries, context, options \\ nil)
    def new_directive(name, for_node, entries, context, options) when not is_list(entries) do
        new_directive(name, for_node, [entries], context, options)
    end
    def new_directive(name, for_node, entries, _context, options) do
        directive_id = new_directive_id(for_node.id, name)
        directive = %GenAI.Session.State.Directive{
                id: directive_id,
                source: {:node, for_node.id},
                entries: entries,
                finger_print: options[:finger_print] || for_node.finger_print || directive_id
            }
            # TODO finger print logic
            {:ok, directive}
    end
    
    defp new_directive_id(source, name) do
        UUID.uuid5(:oid, "#{inspect source}.directive[#{inspect name}]")
    end
  
  #
  #    #-----------------------------------------------
  #    # update_state
  #    #-----------------------------------------------
  #    def update_state(%{__struct__: module} = graph_node, scope, context, options) do
  #        if Code.ensure_loaded?(module) and function_exported?(module, :process_node, 4) do
  #            module.update_state(graph_node, scope, context, options)
  #        else
  #            do_update_state(graph_node, scope, context, options)
  #        end
  #    end
  #    def do_update_state(graph_node, scope, context, options) do
  #
  #    end
  #
  #    #-----------------------------------------------
  #    # update_state_input
  #    #-----------------------------------------------
  #    def update_state_input(%{__struct__: module} = graph_node, scope, context, options) do
  #        if Code.ensure_loaded?(module) and function_exported?(module, :update_state_input, 4) do
  #            module.update_state_input(graph_node, scope, context, options)
  #        else
  #            do_update_state_input(graph_node, scope, context, options)
  #        end
  #    end
  #
  #
  #    def do_update_state_input(graph_node, scope = Node.scope(), context, options) do
  #        with config = %{input: x} <- GenAI.Session.NodeProtocol.graph_node_protocol_options(graph_node, context, options) do
  #            GenAI.Session.Node.Input.expand_inputs(config.input, scope, context, options)
  #        end
  #    end
  #
  #    #-----------------------------------------------
  #    # node_directives
  #    #-----------------------------------------------
  #    def node_directives(%{__struct__: module} = graph_node, input, finger_print_key, scope, context, options) do
  #        if Code.ensure_loaded?(module) and function_exported?(module, :update_state_input, 6) do
  #            module.directives(graph_node, input, finger_print_key, scope, context, options)
  #        else
  #            do_node_directives(graph_node, input, finger_print_key, scope, context, options)
  #        end
  #    end
  #    def do_node_directives(graph_node, input, finger_print_key, scope, context, options), do: nil
  #
  #    #-----------------------------------------------
  #    # finger_print_key
  #    #-----------------------------------------------
  #    def finger_print_key(%{__struct__: module} = graph_node, input, default_key, scope, context, options) do
  #        if Code.ensure_loaded?(module) and function_exported?(module, :finger_print_key, 6) do
  #            module.finger_print_key(graph_node, input, default_key, scope, context, options)
  #        else
  #            do_finger_print_key(graph_node, input, default_key, scope, context, options)
  #        end
  #    end
  #    def do_finger_print_key(graph_node, input, default_key, scope, context, options), do: nil
  #
  #    #-----------------------------------------------
  #    # finger_print
  #    #-----------------------------------------------
  #    def finger_print(%{__struct__: module} = graph_node, finger_print_key, scope, context, options) do
  #        if Code.ensure_loaded?(module) and function_exported?(module, :finger_print, 5) do
  #            module.finger_print(graph_node, finger_print_key, scope, context, options)
  #        else
  #            do_finger_print(graph_node, finger_print_key, scope, context, options)
  #        end
  #    end
  #
  #    def do_finger_print(graph_node, finger_print_key, scope, context, options) do
  #        nil
  #    end
  #
  #
  #===========================================================================
  # Helpers
  #===========================================================================



end
