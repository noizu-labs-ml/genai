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
    alias GenAI.Session.NodeProtocol.DefaultProvider, as: Provider
    
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
            %{__struct__: module} = this,
            Node.scope(
                graph_container: graph_container,
                session_state: session_state
            ), context, options) do
        # TODO if literal (int/float/string) - otherwise not a concrete value
        selector = Provider.new_selector({:setting, this.setting}, {:concrete, this.value})
        directive = Provider.new_directive(this.setting, this, selector, context, options)
        session_state = GenAI.Session.State.append_directive(session_state, directive, context, options)
        GenAI.Session.NodeProtocol.DefaultProvider.process_node_response(
            this,
            graph_container,
            Node.process_update(session_state: session_state)
        )
    end
end