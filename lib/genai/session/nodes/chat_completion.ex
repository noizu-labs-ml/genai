#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.ChatCompletion do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    defnodetype [
        model: term,
        provider: term,
        seed: term,
        choices: term,
        usage: term,
        details: term,
    ]
    
    defnodestruct [
        model: nil,
        provider: nil,
        seed: nil,
        choices: nil,
        usage: nil,
        details: nil,
    ]
    
    defmodule Choice do
        defstruct [
            index: nil,
            message: nil,
            finish_reason: nil,
        ]
    end
    
    defmodule Usage do
        defstruct [
            prompt_tokens: nil,
            total_tokens: nil,
            completion_tokens: nil,
        ]
    end
end
