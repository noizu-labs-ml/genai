#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defmodule GenAI.Session.Records do
    @moduledoc """
    Records useed by for preparing/encoding GenAI.Session
    """
    
    require Record
    
    # Calculate effective/tentative value for option
    Record.defrecord(:selector, [id: nil, for: nil, value: nil, directive: nil, inserted_at: nil, updated_at: nil, impacts: [], references: []])
    
    # Constraint on allowed option values.
    Record.defrecord(:constraint, [id: nil, for: nil, value: nil, directive: nil, inserted_at: nil, updated_at: nil, impacts: [], references: []])
    
    # Constraint computed effective option value with cache tag for invalidation.
    Record.defrecord(:effective_value, [value: nil, finger_print: nil, inserted_at: nil, updated_at: nil,]) # tracking fields.
    
    # Constraint computed tentative option value with cache tag for invalidation.
    Record.defrecord(:tentative_value, [value: nil, finger_print: nil, inserted_at: nil, updated_at: nil,]) # tracking fields.


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
        references: [],
        impacts: [],
        updated_on: nil,
    ]
    
    #------------------------
    # apply_setting_path/1
    #------------------------
    @doc """
    Injection point for a selector/constraint path - e.g. state.settings, state.options, state.provider_settings, etc.
    """
    def apply_setting_path({:option, name}), do:
      [Access.key(:options), name]
    def apply_setting_path({:setting, name}), do:
      [Access.key(:settings), name]
    def apply_setting_path({:tool, name}), do:
      [Access.key(:tools), name]
    def apply_setting_path(:model), do:
      [Access.key(:model)]
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
        false
    end
    
    #-------------------------
    # effective_setting/4
    #-------------------------
    @doc """
    Calculate or returned cached effective value for a given setting.
    
    ## Note
    If selector depends on input of other settings/artifcats (like chat thread) it will in turn insure dependencies are resolved.
    """
    def effective_setting(this, state, context, options)
    def effective_setting(nil, state, context, options) do
        {:error, :unset}
    end
    def effective_setting(this, state, context, options) do
      # @TODO cyclic loop protection.
        cond do
            is_nil(this.effective) || effective_expired?(this.effective, state, context, options) ->
              # load dependencies.
                do_effective_setting(this, this.selectors, state, context, options)
            :else ->
                case this.effective do
                    effective_value(value: {:concrete, value}) ->
                        {:ok, {value, state}}
                end
        end
    end
    
    def effective_setting(this, default, state, context, options)
    def effective_setting(nil, default, state, context, options) do
        {:ok, {default, state}}
    end
    def effective_setting(this, default, state, context, options) do
      # @TODO cyclic loop protection.
        cond do
            is_nil(this.effective) || effective_expired?(this.effective, state, context, options) ->
                case do_effective_setting(this, this.selectors, state, context, options) do
                    {:error, :unresolved} -> {:ok, {default, state}}
                    {:error, :unset} -> {:ok, {default, state}}
                    {:ok, {value, state}} -> {:ok, {value, state}}
                end
            :else ->
                case this.effective do
                    effective_value(value: {:concrete, value}) ->
                        {:ok, {value, state}}
                end
        end
    end
    
    
    
    #-------------------------
    # load_references/4
    #-------------------------
    @doc """
    Load all values this item references/requires to process.
    """
    def load_references(this, state, context, options)
    def load_references(nil, state, context, options), do: state
    def load_references(this, state, context, options) do
        Enum.reduce(this.references, state,
            fn name, state ->
              with {:ok, {_, state}} <- GenAI.Session.State.effective_entry(state, name, context, options) do
                  state
              else
                  _ -> state
              end
            end
        )
    end
    
    #-------------------------
    # mark_reference/4
    #-------------------------
    @doc """
    Set active selector for setting.
    """
    def mark_reference(this, name, reference, context, options)
    def mark_reference(nil, name, reference, context, options) do
        %__MODULE__{
            name: name,
            references: [reference],
        }
    end
    def mark_reference(this, name, reference, context, options) do
      # @todo override logic needed.
        %__MODULE__{this|
            name: name,
            references: [reference| this.references],
        }
    end
    
    #-------------------------
    # mark_references/4
    #-------------------------
    @doc """
    Set active selector for setting.
    """
    def mark_references(this, name, references, context, options)
    def mark_references(nil, name, references, context, options) do
        %__MODULE__{
            name: name,
            references: references,
        }
    end
    def mark_references(this, name, references, context, options) do
      # @todo override logic needed.
        %__MODULE__{this|
            name: name,
            references: references ++ [this.references],
        }
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
    
    #=========================================================================
    # Private Methods
    #=========================================================================
    
    
    defp do_effective_setting(this, [], state, context, options), do: {:error, :unset}
    defp do_effective_setting(this, [h|t], state, context, options) do
        case h do
            selector(value: :chain) ->
                do_effective_setting(this, t, state, context, options)
            selector(value: x = {:concrete, value}) ->
                e = effective_value(value: x)
                state = put_in(state, apply_setting_path(this.name) ++ [Access.key(:effective)], e)
                {:ok, {value, state}}
            selector(value: {:lambda, lambda}) ->
                case lambda.(h, state, context, options) do
                    {:ok, {unpacked, state}} ->
                        do_effective_setting(this, [selector(h, value: unpacked)|t], state, context, options)
                end
        end
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
        inserted_at: nil,
        updated_at: nil,
    ]
    
    #-------------------------
    # fingerprint/4
    #-------------------------
    @doc """
    Calculate a unique fingerprint for directive based on selector/constraint dependency values.
    """
    def fingerprint(this, state, context, options) do
      # TODO Impelment - uuid5 concat of entry fingerprints.
      # Returns fingerprint and updated state.
        this.id
    end
    
    #-------------------------
    # apply_directive/4
    #-------------------------
    @doc """
    Unpack a directive and resulting setting entry selector/constraint entries.
    """
    def apply_directive(directive, state, context, options \\ nil)
    def apply_directive(directive, state, context, options) do
        Enum.reduce(
            directive.entries,
            state,
            fn
                x = selector(for: setting, impacts: impacts), state ->
                    x = selector(x, directive: directive.id)
                    state = state
                            |> update_in(
                                   GenAI.Session.State.SettingEntry.apply_setting_path(setting),
                                   & GenAI.Session.State.SettingEntry.apply_selector(&1, x, context, options)
                               )
                    
                    # Tap Settings which are impacted by this selector
                    impacts = if not is_list(impacts), do: [impacts], else: impacts
                    state = Enum.reduce(
                        impacts,
                        state,
                        fn impact, state ->
                          state = state
                                  |> update_in(
                                         GenAI.Session.State.SettingEntry.apply_setting_path(impact),
                                         & GenAI.Session.State.SettingEntry.mark_reference(&1, impact, setting, context, options))
                        end)
                
                
                x = constraint(for: setting), state ->
                    x = constraint(x, directive: directive.id)
                    state
                            |> update_in(
                                   GenAI.Session.State.SettingEntry.apply_setting_path(setting),
                                   & GenAI.Session.State.SettingEntry.apply_constraint(&1, x, context, options)
                               )
            end
        )
    end
end

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
        updated_on: nil,
    ]
end

defmodule GenAI.Session.State do
    @moduledoc """
    Represent status/state such as node state, sessions, message thread, etc.
    """
    
    require GenAI.Session.Records
    import GenAI.Session.Records
    
    defstruct [
        directives: [],
        directive_position: 0,
        
        thread: [],
        
        options: %{},
        settings: %{},
        model_settings: %{},
        provider_settings: %{},
        model: nil,
        
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
    Check if pending directives are not yet applied.
    """
    def pending_directives?(state) do
        length(state.directives) > state.directive_position
    end
    
    #-----------------------
    # monitor/4
    #-----------------------
    @doc """
    Add additional directive to list.
    """
    def append_directive(state, directive, context, options) do
        %__MODULE__{state|
            directives: state.directives ++ [directive]
        }
    end
    
    #-----------------------
    # monitor/4
    #-----------------------
    @doc """
    Expand out/apply directive when settings required.
    """
    def apply_directives(state, context, options \\ nil)
    def apply_directives(state, context, options) do
        if pending_directives?(state) do
            state = Enum.reduce(
                state.directive_position ..  length(state.directives) - 1 ,
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
    
    
    #-----------------------
    # drive get effective option/value
    #-----------------------
    defp do_effective(state, path, context, options) do
      # Advance Unnapplied directives
        state = apply_directives(state, context, options)
        entry = get_in(state, GenAI.Session.State.SettingEntry.apply_setting_path(path))
        
        # Insure referenced settings are loaded if required
        position = state.directive_position
        state = GenAI.Session.State.SettingEntry.load_references(entry, state, context, options)
        state = apply_directives(state, context, options)
        entry = get_in(state, GenAI.Session.State.SettingEntry.apply_setting_path(path))
        unless state.directive_position == position do
          # Repeat if injected directives have been added until resolved.
            do_effective(state, path, context, options)
        else
          # Proceed
            GenAI.Session.State.SettingEntry.effective_setting(entry, state, context, options)
        end
    end
    
    
    #-----------------------
    # settings/3
    #-----------------------
    @doc """
    Get effective settings map.
    """
    def settings(state, context, options) do
      # walk over all settings, recursively until no new virtual directives are appended.
      # return effective values map
      # %{settings: %{temperature: 5, tokesn: 7}, model: :phillip, ...}
        {:ok, :wip}
    end
    
    #-----------------------
    # effective_entry/4
    #-----------------------
    @doc """
    Get an effective setting entry of any type. (setting, provider_setting, etc.)
    """
    def effective_entry(state, entry, context, options)
    def effective_entry(state, entry, context, options), do:
      do_effective(state, entry, context, options)
    
    
    #-----------------------
    # effective_entry/5
    #-----------------------
    def effective_entry(state, entry, default, context, options)
    def effective_entry(state, entry, default, context, options), do:
      do_effective(state, entry, default, context, options)
    
    #-----------------------
    # effective_setting/4
    #-----------------------
    @doc """
    Get an setting entry.
    """
    def effective_setting(state, name, context, options)
    def effective_setting(state, name, context, options), do:
      do_effective(state, {:setting, name}, context, options)
    
    
    #-----------------------
    # effective_setting/5
    #-----------------------
    @doc """
    Get an setting entry or default if not set
    """
    def effective_setting(state, name, default, context, options)
    def effective_setting(state, name, default, context, options), do:
      do_effective(state, {:setting, name}, default, context, options)
    
    
    #-----------------------
    # effective_option/4
    #-----------------------
    @doc """
    Get a option entry.
    """
    def effective_option(state, name, context, options)
    def effective_option(state, name, context, options), do:
      do_effective(state, {:option, name}, context, options)
    
    #-----------------------
    # effective_option/5
    #-----------------------
    @doc """
    Get a option entry or default if not set.
    """
    def effective_option(state, name, default, context, options)
    def effective_option(state, name, default, context, options), do:
      do_effective(state, {:option, name}, default, context, options)
    
    
    
    #-----------------------
    # effective_model_setting/4
    #-----------------------
    @doc """
    Get model setting
    """
    def effective_model_setting(state, name, context, options)
    def effective_model_setting(state, name, context, options), do:
      do_effective(state, {:model, name}, context, options)
    
    #-----------------------
    # effective_model_setting/5
    #-----------------------
    @doc """
    Get model setting entry or default if not set.
    """
    def effective_model_setting(state, name, default, context, options)
    def effective_model_setting(state, name, default, context, options), do:
      do_effective(state, {:model, name}, default, context, options)
    
    
    #-----------------------
    # effective_provider_setting/5
    #-----------------------
    @doc """
    Get provider setting
    """
    def effective_provider_setting(state, provider, setting, context, options)
    def effective_provider_setting(state, provider, setting, context, options), do:
      do_effective(state, {:provider_setting, provider, setting}, context, options)
    
    #-----------------------
    # effective_provider_setting/6
    #-----------------------
    @doc """
    Get provider setting entry or default if not set.
    """
    def effective_provider_setting(state, provider, setting, default, context, options)
    def effective_provider_setting(state, provider, setting, default, context, options), do:
      do_effective(state, {:provider_setting, provider, setting}, default, context, options)
    
    
    
    #-----------------------
    # effective_model/4
    #-----------------------
    @doc """
    Get model setting
    """
    def effective_model(state, name, context, options)
    def effective_model(state, name, context, options), do:
      do_effective(state, {:model, name}, context, options)
    
    #-----------------------
    # effective_model/5
    #-----------------------
    @doc """
    Get model setting entry or default if not set.
    """
    def effective_model(state, name, default, context, options)
    def effective_model(state, name, default, context, options), do:
      do_effective(state, {:model, name}, default, context, options)
    
    
    #=========================================================================
    # Private Methods
    #=========================================================================
    
    defp do_effective(state, path, default, context, options) do
      # Advance Unnapplied directives
        state = apply_directives(state, context, options)
        entry = get_in(state, GenAI.Session.State.SettingEntry.apply_setting_path(path))
        # Insure referenced settings are loaded if required
        position = state.directive_position
        state = GenAI.Session.State.SettingEntry.load_references(entry, state, context, options)
        state = apply_directives(state, context, options)
        entry = get_in(state, GenAI.Session.State.SettingEntry.apply_setting_path(path))
        if state.directive_position == position do
          # Proceed
            GenAI.Session.State.SettingEntry.effective_setting(entry, default, state, context, options)
        else
          # Repeat if injected directives have been added until resolved.
            do_effective(state, path, default, context, options)
        end
    end

end