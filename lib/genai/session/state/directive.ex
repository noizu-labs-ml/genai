
#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
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
