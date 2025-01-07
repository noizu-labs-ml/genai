#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Tool do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    defnodetype [
        parameters: term,
    ]
    
    defnodestruct [
        parameters: %{}
    ]
end


defimpl GenAI.ToolProtocol, for: GenAI.Tool do
    def supported?(_), do: true
end