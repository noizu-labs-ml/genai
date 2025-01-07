#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Setting do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    defnodetype [
        setting: term,
        value: term,
    ]
    
    defnodestruct [
        setting: nil,
        value: nil,
    ]
end


defimpl GenAI.SettingProtocol, for: GenAI.Setting do
    def supported?(_), do: true
end