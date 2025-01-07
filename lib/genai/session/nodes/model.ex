#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Model do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    @derive GenAI.Session.NodeProtocol
    defnodetype [
        provider: term,
        model: term,
        details: term,
    ]
    
    defnodestruct [
        provider: nil,
        model: nil,
        details: nil
    ]
    
    def node_type(%__MODULE__{}), do: GenAI.Model
end
