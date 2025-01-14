#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

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
    def apply_setting_path({:stack, name}), do:
      [Access.key(:stack), name]
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
