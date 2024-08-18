#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defprotocol GenAI.SettingProtocol do
    def supported?(subject)
end