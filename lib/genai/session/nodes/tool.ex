#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Tool do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    @derive GenAI.Session.NodeProtocol
    defnodetype [
        parameters: term,
    ]
    
    defnodestruct [
        parameters: %{}
    ]
    
    def node_type(%__MODULE__{}), do: GenAI.Tool
end