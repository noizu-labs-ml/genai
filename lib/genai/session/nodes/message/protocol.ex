#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defprotocol GenAI.MessageProtocol do
    def supported?(subject)
end