defmodule GenAI.Session.NodeProtocol.Runner do
    require GenAI.Session.NodeProtocol.Records
    alias GenAI.Session.NodeProtocol.Records, as: Node
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