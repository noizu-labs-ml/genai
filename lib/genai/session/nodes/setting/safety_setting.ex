#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Setting.SafetySetting do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    @derive GenAI.Session.NodeProtocol
    defnodetype [
        category: term,
        threshold: term,
    ]
    
    defnodestruct [
        category: nil,
        threshold: nil,
    ]
    
    def node_type(%__MODULE__{}), do: GenAI.Setting
end
