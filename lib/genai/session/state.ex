#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defmodule GenAI.Session.State do
    @moduledoc false
    
    defstruct [
        vsn: 1.0
    ]
    
    def new(options \\ nil)
    def new(_) do
        %__MODULE__{
        
        }
    end
    
end
