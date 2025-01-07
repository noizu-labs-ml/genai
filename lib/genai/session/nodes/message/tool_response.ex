#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message.ToolResponse do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
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
end

defimpl GenAI.MessageProtocol, for: GenAI.Message.ToolResponse do
    def supported?(_), do: true
end