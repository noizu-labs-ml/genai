#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Setting do
    @vsn 1.0
    @moduledoc false
    
    require GenAI.Session.NodeProtocol.Records
    alias GenAI.Session.NodeProtocol.Records, as: Node
    require GenAI.Graph.Link.Records
    alias GenAI.Graph.Link.Records, as: Link
    require GenAI.Session.Records
    alias GenAI.Session.Records, as: S
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    @derive GenAI.Session.NodeProtocol
    defnodetype [
        setting: term,
        value: term,
    ]
    
    defnodestruct [
        setting: nil,
        value: nil,
    ]
    
    def node_type(%__MODULE__{}), do: GenAI.Setting
    
    def process_node(graph_node, scope, context, options)
    def process_node(
            %{__struct__: module} = graph_node,
            Node.scope(
                graph_node: original_graph_node,
                graph_link: graph_link,
                graph_container: graph_container,
                session_state: session_state,
                session_runtime: session_runtime
            ), context, options) do
        directive = %GenAI.Session.State.Directive{
            id: UUID.uuid5(graph_node.id, "directive-1"),
            source: {:node, graph_node.id},
            entries: [
                S.selector(for: {:setting, graph_node.setting}, value: {:concrete, graph_node.value})
            ]
        }
        session_state = GenAI.Session.State.append_directive(session_state, directive, context, options)
        GenAI.Session.NodeProtocol.DefaultProvider.process_node_response(
            graph_node,
            graph_container,
            Node.process_update(session_state: session_state)
        )
    end
end