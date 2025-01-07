#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Model do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
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
end


defimpl GenAI.ModelProtocol, for: GenAI.Model do
    def supported?(_), do: true
end