#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================



defmodule GenAI.Session.State.Records do
   require Record
   
   @type id :: term
   @type setting :: term
   @type source :: {:rule, id}
   @type weight :: integer
   @type selector_type :: :interstitial | :defaut | :user | :derived | atom
   
   @type warn_action :: {:log, :info | :warning | :error} |  :error | :raise
   @type warn_settings :: [
                    unmet: warn_action,
                    on_override: warn_action,
                    ]
   
   # tuple {:<, 500}, {:in, [a,b,c]}, Module with constraint method, Struct with constraint behavior, mfa, function/3 (constraint, setting, state)
   @type constraint_value :: {m :: Module, f :: atom, a :: list()} | Module | struct() | function
   
   
   # tuple {:<, 500}, {:in, [a,b,c]}, Module with constraint method, Struct with constraint behavior, mfa, function/3 (constraint, setting, state)
   @type selector_value :: {m :: Module, f :: atom, a :: list()} | Module | struct() | function
   @type rule_source :: {:node, term} | :config | {:derived, {setting, :selector, id}} | {:derived, {setting, :constraint, id}} | {:derived, {setting, :tentative, id}} | {:derived, {setting, :effective, id}}

   Record.defrecord(:selector, [id: nil, setting: nil, selector: nil, source: nil, weight: nil, type: nil, meta: nil])
   Record.defrecord(:constraint, [id: nil, setting: nil, constraint: nil, source: nil, weight: nil, required: false, warn_settings: nil, meta: nil])
   Record.defrecord(:rule, [id: nil, source: nil])
   Record.defrecord(:tentative_value, [id: nil, type: nil, value: nil, cache_key: nil, meta: nil])
   Record.defrecord(:effective_value, [id: nil, value: nil, cache_key: nil, meta: nil])
   
   @type selector :: record(:selector, [id: id, setting: setting, selector: selector_value, source: source, weight: weight, type: selector_type, meta: term])
   @type constraint :: record(:constraint, [id: id, setting: setting, constraint: constraint_value, source: source, weight: weight, required: boolean, warn_settings: warn_settings, meta: term])
   @type rule :: record(:rule, [id: id, source: rule_source])
   @type tentative_value :: record(:tentative_value, [id: id, type: term, value: term, cache_key: term, meta: term])
   @type effective_value :: record(:effective_value, [id: id, value: term, cache_key: term, meta: term])
   
   
   
end


defmodule GenAI.Session.Rule do
    defstruct [
        id: nil,
        source: nil,
        finger_print: nil,
        references: nil,
        modifies: nil,
        selectors: %{},
        constraints: %{},
    ]
end

defmodule GenAI.Session.NodeState do
    defstruct [
        id: nil,
        finger_print: nil,
        updated_at: nil,
        core: nil,
        ephermal: nil
    ]
end


defmodule GenAI.Session.Entry do
    defstruct [
        name: nil,
        selectors: [],
        constraints: [],
        effective: nil,
        tentative: nil,
        dependencies: [],
        dependents: [],
    ]
end


defmodule GenAI.Session.StateBehaviour do
    @moduledoc false

end


defmodule GenAI.Session.State do
    @moduledoc false

    # TODO logic to avoid reprocessing already applied nodes/rules.
    # Some nodes/rules have dynamic parts, some are fixed.
    # once graph is already processed subsequent runs should be light touch and only generate new nodes and nodes with changes.
    # nodes should provide a version/key field to determine if a change has occured/should occur. e.g. indicate they are dynamic.
    
    defstruct [
        # Inferred Settings/State
        settings: %{},
        tools: %{},
        model_settings: %{},
        provider_settings: %{},
      
      
        # id -> applied message/effective (containing any generated/injected parts, memories, etc.), a message may wrap multiple nodes that are combined to build a final message like preparing a plan, injecting memories, dynamic insertion, etc to prepare final effective message.
        # may not be a final form message may contain stub elements that are processed las tminute by provider such as formatting instructions as xml versus json, etc.
        messages: %{},
        message_sequence: [], # by id
    
        rules: %{}, # id -> message
        rule_sequence: [], # by id
    
        # node state - (state only not entire object), externalized object sent by node.
        graph_nodes: %{},
        graph_links: %{},
    
        # running options
        monitors: %{},
        vsn: 1.0
    ]
    
    #===========================================================================
    #
    #===========================================================================
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

    # with_setting, model, tool, ... default_api_key (pushes to top of rules), ...
    
    # effective_model, effective_setting, effective_model_settings, effective_provider_settings, messages, tools, rules, monitors, ...
  
  #=============================================================================
  #
  #=============================================================================
  

end


