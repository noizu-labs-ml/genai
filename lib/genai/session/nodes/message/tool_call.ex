#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message.ToolCall do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
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
end

defimpl GenAI.MessageProtocol, for: GenAI.Message.ToolCall do
    def supported?(_), do: true
end