#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    defnodetype [
        role: term,
        content: term,
    ]
    
    defnodestruct [
        role: nil,
        content: nil,
    ]
    
    
    def new(role, message) do
        id = UUID.uuid4()
        %__MODULE__{
            id: id,
            role: role,
            content: message
        }
    end
    
    def user(message) do
        new(:user, message)
    end
    
    def system(message) do
        new(:system, message)
    end
    
    def assistant(message) do
        new(:assistant, message)
    end
end


defimpl GenAI.MessageProtocol, for: GenAI.Message do
    def supported?(_), do: true
end