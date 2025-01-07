#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defmodule GenAI.Session.State do
    @moduledoc false
    
    defstruct [
        monitors: %{},
        vsn: 1.0
    ]
    
    def new(options \\ nil)
    def new(_) do
        %__MODULE__{
        
        }
    end

    def initialize(state, runtime, context, options \\ nil)
    def initialize(state, _runtime, _context, _options) do
      {:ok, state}
    end

    def monitor(state, runtime, context, options \\ nil)
    def monitor(state, runtime, _, _) do
      state = %__MODULE__{state| monitors: :wip}
      {:ok, {state, runtime}}
    end


end
