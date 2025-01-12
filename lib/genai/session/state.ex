#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================


defmodule GenAI.Session.Records do
    @moduledoc """
    Records useed by for preparing/encoding GenAI.Session
    """
    
    require Record
    
    # Calculate effective/tentative value for option
    Record.defrecord(:selector, [for: nil, value: nil, directive: nil])
    
    # Constraint on allowed option values.
    Record.defrecord(:constraint, [for: nil, value: nil, directive: nil])
    
    # Constraint computed effective option value with cache tag for invalidation.
    Record.defrecord(:effective_value, [value: nil]) # tracking fields.
    
    # Constraint computed tentative option value with cache tag for invalidation.
    Record.defrecord(:tentative_value, [value: nil]) # tracking fields.
end

defmodule GenAI.Session.State.SettingEntry do
    @moduledoc """
    Option record constructed from directives value constructor.
    
    # Note
    Directives defines constraints/selectors for calculating dynamic (or concrete) values for a given setting or group of settings.
    """
    
    require GenAI.Session.Records
    import GenAI.Session.Records
    defstruct [
        name: nil,
        effective: nil,
        selectors: [],
        constraints: [],
    ]
    
    #------------------------
    # apply_setting_path/1
    #------------------------
    @doc """
    Injection point for a selector/constraint path
    """
    def apply_setting_path({:option, name}), do:
      [Access.key(:options), name]
    def apply_setting_path({:setting, name}), do:
      [Access.key(:settings), name]
    def apply_setting_path({:model_setting, model, name}), do:
      [Access.key(:model_settings), model, name]
    def apply_setting_path({:provider_setting, provider, name}), do:
      [Access.key(:provider_settings), provider, name]
    
    #------------------------
    # effective_expired?/4
    #------------------------
    @doc """
    Verify is stored effective value must be recalculated due to input value changes or other factors such as ttl.
    """
    def effective_expired?(this, state, context, options) do
      # TODO Implement logic
        {false, state}
    end
    
    #-------------------------
    # effective_value/4
    #-------------------------
    @doc """
    Calculate or returned cahced effective value for a given setting.
    
    ## Note
    If selector depends on input of other settings/artifcats (like chat thread) it will in turn insure dependencies are resolved.
    """
    def effective_value(this, state, context, options)
    def effective_value(nil, state, context, options) do
        {:error, :not_set}
    end
    def effective_value(this, state, context, options) do
      # @TODO support more selector types
      # @TODO support dependency resolution
      # @TODO cyclic loop protection.
        cond do
            is_nil(this.effective) || effective_expired?(this.effective, state, context, options) ->
                with [h|_] <- this.selectors do
                    case h do
                        x = selector(value: {:concrete, value}) ->
                            e = effective_value(value: x)
                            put_in(state, apply_setting_path(this.name) ++ [Access.key(:effective)], e)
                            {:ok, {value, state}}
                    end
                else
                    _ -> {:ok, :unset}
                end
            :else ->
                case this.effective do
                    effective_value(value: {:concrete, value}) ->
                        {:ok, {value, state}}
                end
        end
    end
    
    def effective_value(this, default, state, context, options)
    def effective_value(nil, default, state, context, options) do
        {:ok, {default, state}}
    end
    def effective_value(this, default, state, context, options) do
      # @TODO support more selector types
      # @TODO support dependency resolution
      # @TODO cyclic loop protection.
        cond do
            is_nil(this.effective) || effective_expired?(this.effective, state, context, options) ->
                with [h|_] <- this.selectors do
                    case h do
                        x = selector(value: {:concrete, value}) ->
                            e = effective_value(value: x)
                            put_in(state, apply_setting_path(this.name) ++ [Access.key(:effective)], e)
                            {:ok, {value, state}}
                    end
                    else
                    _ -> {:ok, {default, state}}
                end
            :else ->
                case this.effective do
                    effective_value(value: {:concrete, value}) ->
                        {:ok, {value, state}}
                end
        end
    end
    
    #-------------------------
    # apply_selector/4
    #-------------------------
    @doc """
    Set active selector for setting.
    """
    def apply_selector(this, selector, context, options)
    def apply_selector(nil, selector = selector(for: name), context, options) do
        %__MODULE__{
            name: name,
            selectors: [selector],
        }
    end
    def apply_selector(this, selector, context, options) do
      # @TODO - override/merge logic
        %__MODULE__{this|
            selectors: [selector |this.selectors],
        }
    end
    
    #-------------------------
    # apply_constraint/4
    #-------------------------
    @doc """
    Apply constraint on allowed values like temperature must be > 95, model but support tools, etc.
    """
    def apply_constraint(this, constraint, context, options)
    def apply_constraint(nil, constraint = constraint(for: name), context, options) do
        %__MODULE__{
            name: name,
            constraints: [constraint],
        }
    end
    
    def apply_constraint(this, constraint, context, options) do
      # @TODO Merge/Overridde Logic
        %__MODULE__{this|
            constraints: [constraint |this.constraints],
        }
    end
end

defmodule GenAI.Session.State.Directive do
    @moduledoc """
    A Directive specifying which models, options, etc. values should be applied to session state.
    
    ## Note
    This is a basic Directive, more advanced directives may be dynamic with resulting entries calculated at apply time
    Based on other setting/global values in state.
    """
    require GenAI.Session.Records
    import GenAI.Session.Records
    
    defstruct [
        id: nil,
        source: nil,
        finger_print: nil,
        entries: [],
    ]
    
    @doc """
    Calculate a unique fingerprint for directive based on selector/constraint dependency values.
    """
    def fingerprint(this, state, context, options) do
      # TODO Impelment - uuid5 concat of entry fingerprints.
      # Returns fingerprint and updated state.
        this.id
    end
    
    
    def apply_directive(directive, state, context, options \\ nil)
    def apply_directive(directive, state, context, options) do
        Enum.reduce(
            directive.entries,
            state,
            fn
                x = selector(for: setting), state ->
                    x = selector(x, directive: directive.id)
                    state = state
                            |> update_in(
                                   GenAI.Session.State.SettingEntry.apply_setting_path(setting),
                                   & GenAI.Session.State.SettingEntry.apply_selector(&1, x, context, options)
                               )
                x = constraint(for: setting), state->
                    x = constraint(x, directive: directive.id)
                    state = state
                            |> update_in(
                                   GenAI.Session.State.SettingEntry.apply_setting_path(setting),
                                   & GenAI.Session.State.SettingEntry.apply_constraint(&1, x, context, options)
                               )
            end
        )
    end
end


defmodule GenAI.Session.State do
    @moduledoc """
    Represent status/state such as node state, sessions, message thread, etc.
    """
    

    require GenAI.Session.Records
    import GenAI.Session.Records
    
    defstruct [
        processing: %{},
        directives: [],
        
        options: %{},
        settings: %{},
        model_settings: %{},
        provider_settings: %{},
        model: nil,
        
        directive_position: 0,
        monitors: %{},
        vsn: 1.0
    ]
    
    #===========================================================================
    #
    #===========================================================================
    
    #-----------------------
    # new/1
    #-----------------------
    def new(options \\ nil)
    def new(_) do
        %__MODULE__{
        
        }
    end
    
    #-----------------------
    # initialize/4
    #-----------------------
    def initialize(state, runtime, context, options \\ nil)
    def initialize(state, _runtime, _context, _options) do
        {:ok, state}
    end
    
    #-----------------------
    # monitor/4
    #-----------------------
    def monitor(state, runtime, context, options \\ nil)
    def monitor(state, runtime, _, _) do
        state = %__MODULE__{state| monitors: :wip}
        {:ok, {state, runtime}}
    end
    
    #-----------------------
    # pending_directives?/1
    #-----------------------
    @doc """
    Check if pending directives should be applied.
    """
    def pending_directives?(state) do
        length(state.directives) > state.directive_position
    end
    
    
    
    def apply_directives(state, context, options \\ nil)
    def apply_directives(state, context, options) do
        if pending_directives?(state) do
            state = Enum.reduce(
                state.directive_position .. length(state.directives) -1,
                state,
                fn
                    index, state ->
                        directive = Enum.at(state.directives, index)
                        GenAI.Session.State.Directive.apply_directive(directive, state, context, options)
                end
            )
            %__MODULE__{state |
                directive_position: length(state.directives)
            }
        else
            state
        end
    end
    
    def effective_setting(state, name, context, options)
    def effective_setting(state, name, context, options) do
        state = apply_directives(state, context, options)
        entry = get_in(state, GenAI.Session.State.SettingEntry.apply_setting_path({:setting, name}))
        GenAI.Session.State.SettingEntry.effective_value(entry, state, context, options)
    end
    
    def effective_setting(state, name, default, context, options)
    def effective_setting(state, name, default, context, options) do
        state = apply_directives(state, context, options)
        entry = get_in(state, GenAI.Session.State.SettingEntry.apply_setting_path({:setting, name}))
        GenAI.Session.State.SettingEntry.effective_value(entry, default, state, context, options)
    end
end
