#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defprotocol GenAI.Session.NodeProtocol do
  @doc """
  Process node and proceed to next step.
  """
  
  def process_node(graph_node, graph_link, container, state, runtime, context, options)
  def node_type(graph_node)
end

defimpl GenAI.Session.NodeProtocol, for: Any do
    defmacro __deriving__(module, _struct, options) do
        quote do
            defimpl GenAI.Session.NodeProtocol, for: unquote(module) do
                @provider unquote(options[:provider]) || GenAI.Session.NodeProtocol.DefaultProvider
                
                defdelegate node_type(subject), to: @provider
                defdelegate process_node(subject, graph_link, container, state, runtime, context, options), to: @provider
            end
        end
    end
end




defmodule GenAI.Session.NodeProtocol.DefaultProvider do
    require GenAI.Session.Node.Records
    alias GenAI.Session.Node.Records, as: Node
    require GenAI.Graph.Link.Records
    alias GenAI.Graph.Link.Records, as: Link
    
    def process_node(%{__struct__: module} = graph_node, graph_link, graph_container, session_state, session_runtime, context, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :process_node, 7) do
            module.process_node(graph_node, graph_link, graph_container, session_state, session_runtime, context, options)
        else
            do_process_node(graph_node, graph_link, graph_container, session_state, session_runtime, context, options)
        end
    end
    
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
    
    
    def do_process_node(graph_node, graph_link, container, state, runtime, context, options)
    def do_process_node(%{__struct__: module} = graph_node, graph_link, container, state, runtime, context, options) do
      # Update state,
      # Emit Telemetry/Monitors
      # Populate effective state in state under id.
        updated_state = state
        # TODO - outbound links protocol method needed.
        with {:ok, links} <-
               GenAI.Graph.NodeProtocol.outbound_links(graph_node, container, expand: true) do
          
          
          # Single node support only
            links = links
                    |> Enum.map(fn {socket, links} -> links end)
                    |> List.flatten()
            case links do
                [] -> Node.process_end(exit_on: {graph_node, :no_links}, update: Node.process_update(state: updated_state))
                [link] ->
                    Node.process_next(link: link, update: Node.process_update(state: updated_state))
            end
        end
    end
    
    
end






defmodule GenAI.Session.NodeProtocol.Runner do
  require GenAI.Session.Node.Records
  alias GenAI.Session.Node.Records, as: Node
  require GenAI.Graph.Link.Records
  alias GenAI.Graph.Link.Records, as: Link


  def apply_process_update(graph_node, graph_link, graph_container, session_state, session_runtime, updates, context, options)
  def apply_process_update(
        graph_node,
        graph_link,
        graph_container,
        session_state,
        session_runtime,
        Node.process_update(
          node: graph_node_changes,
          link: graph_link_changes,
          container: graph_container_changes,
          state: session_state_changes,
          runtime: session_runtime_changes
        ),
        _context,
        _options
      ) do

    r = Node.process_update(
      node:  graph_node_changes || graph_node,
      link: graph_link_changes || graph_link,
      container: graph_container_changes || graph_container,
      state: session_state_changes || session_state,
      runtime: session_runtime_changes || session_runtime
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


  def do_process_node(graph_node, graph_link, graph_container, session_state, session_runtime, context, options)
  def do_process_node(graph_node, graph_link, graph_container, session_state, session_runtime, context, options) do

    case GenAI.Session.NodeProtocol.process_node(graph_node, graph_link, graph_container, session_state, session_runtime, context, options)
      do
      Node.process_next(link: next_graph_link, update: processing_update) ->
        with {:ok, params = Node.process_update()} <- apply_process_update(
          graph_node,
          graph_link,
          graph_container,
          session_state,
          session_runtime,
          processing_update,
          context,
          options
        ),
             Node.process_update(
               node: graph_node,
               link: graph_link,
               container: graph_container,
               state: session_state,
               runtime: session_runtime
             ) <- params,
             {:ok, target = Link.connector()} <- GenAI.Graph.Link.target_connector(next_graph_link),
             #  @ODO should be node protocol
             {:ok, next_graph_node} <- GenAI.Graph.node(graph_container, target) do
          do_process_node(next_graph_node, next_graph_link, graph_container, session_state, session_runtime, context, options)
        end

      return = Node.process_end(exit_on: exit_on, update: processing_update) ->
        with {:ok, params = Node.process_update()}
             <- apply_process_update(
          graph_node,
          graph_link,
          graph_container,
          session_state,
          session_runtime,
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
          graph_node,
          graph_link,
          graph_container,
          session_state,
          session_runtime,
          processing_update,
          context,
          options
        )  do
          Node.process_error(return, update: params)
        end
    end
  end
end