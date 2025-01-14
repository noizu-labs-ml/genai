#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
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
        thread_messages: %{},
        stack: %{},
        data_generators: %{},
    
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
    
    
    
    
    def query_data_generator(state, key, get_and_update, context, options)
    def query_data_generator(state, key, get_and_update, context, options) do
        with true <- !is_nil(state.data_generators[key])  || {:error, {{:generator, key}, :not_found}},
             generator <- state.data_generators[key],
             {:ok, {response, {generator, state}}} <- apply(get_and_update, [generator, state, context, options]) do
            state = put_in(state, [Access.key(:data_generators), key], generator)
            {:ok, {response, state}}
            
            
        end
    end
    
    
    
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