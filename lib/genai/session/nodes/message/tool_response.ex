#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message.ToolResponse do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    @derive GenAI.Session.NodeProtocol
    defnodetype [
        tool_name: any,
        tool_response: any,
        tool_call_id: any,
    ]
    
    defnodestruct [
        tool_name: nil,
        tool_response: nil,
        tool_call_id: nil,
    ]
    
    def node_type(%__MODULE__{}), do: GenAI.Message
end
