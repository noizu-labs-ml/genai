#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Setting.ProviderSetting do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    defnodetype [
        provider: any,
        setting: any,
        value: any
    ]
    
    defnodestruct [
        provider: nil,
        setting: nil,
        value: nil
    ]
end

defimpl GenAI.SettingProtocol, for: GenAI.Setting.ProviderSetting do
    def supported?(_), do: true
end