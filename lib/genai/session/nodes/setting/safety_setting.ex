#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Setting.SafetySetting do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    defnodetype [
        category: term,
        threshold: term,
    ]
    
    defnodestruct [
        category: nil,
        threshold: nil,
    ]
end


defimpl GenAI.SettingProtocol, for: GenAI.Setting.SafetySetting do
    def supported?(_), do: true
end