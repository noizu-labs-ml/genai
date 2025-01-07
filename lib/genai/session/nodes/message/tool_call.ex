#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message.ToolCall do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    @derive GenAI.Session.NodeProtocol
    defnodetype [
        role: any,
        content: any,
        tool_calls: any,
    ]
    
    defnodestruct [
        role: nil,
        content: nil,
        tool_calls: nil,
    ]
    
    def node_type(%__MODULE__{}), do: GenAI.Message
end