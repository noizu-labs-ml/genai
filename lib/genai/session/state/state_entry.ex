
#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defmodule GenAI.Session.StateEntry do
    @moduledoc """
    Node/Link/Global stored state.
    """
    require GenAI.Session.Records
    import GenAI.Session.Records
    
    defstruct [
        id: nil,
        state: nil,
        finger_print: nil,
        inserted_at: nil,
        updated_at: nil,
    ]
end
