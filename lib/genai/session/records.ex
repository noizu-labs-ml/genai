#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defmodule GenAI.Session.Records do
    @moduledoc """
    Records used by for preparing/encoding GenAI.Session
    """
    require GenAI.Session.NodeProtocol.Records
    alias GenAI.Session.NodeProtocol.Records, as: Node
    require GenAI.Graph.Link.Records
    alias GenAI.Graph.Link.Records, as: Link
    
    require Record
    
    # Calculate effective/tentative value for option
    Record.defrecord(:selector, [id: nil, handle: nil, for: nil, value: nil, directive: nil, inserted_at: nil, updated_at: nil, impacts: [], references: []])
    
    # Constraint on allowed option values.
    Record.defrecord(:constraint, [id: nil, handle: nil,  for: nil, value: nil, directive: nil, inserted_at: nil, updated_at: nil, impacts: [], references: []])
    
    # Constraint computed effective option value with cache tag for invalidation.
    Record.defrecord(:effective_value, [id: nil, handle: nil, value: nil, finger_print: nil, inserted_at: nil, updated_at: nil,]) # tracking fields.
    
    # Constraint computed tentative option value with cache tag for invalidation.
    Record.defrecord(:tentative_value, [id: nil, handle: nil, value: nil, finger_print: nil, inserted_at: nil, updated_at: nil,]) # tracking fields.
#
#    #------------------
#    # node protocol definition helpers.
#    #------------------
#
#    # retrieve n records from data_generator for a given data_set.
#    Record.defrecord(:data_set, [name: nil, records: 1])
#
#    # Grab value from global stack
#    Record.defrecord(:stack, [item: nil, default: nil])
#    # Grab sub value from global stack
#    Record.defrecord(:stack_item_value, [item: nil, path: [], default: nil])
#
#    # Grab input value
#    Record.defrecord(:input, [value: nil, default: nil])
#    # Grab nested item from input value
#    Record.defrecord(:input_element, [value: nil, path: [], default: nil])
#
#    # grab message state entry or nested entry
#    Record.defrecord(:message, [id: nil, handle: nil])
#    Record.defrecord(:message_value, [id: nil, path: nil])
#    Record.defrecord(:message_filter, [filter: nil])
#    Record.defrecord(:message_filter_value, [filter: nil, path: []])
#
#    # grab link state entry or nested entry
#    Record.defrecord(:link, [id: nil, handle: nil])
#    Record.defrecord(:link_value, [id: nil, handle: nil, path: []])
#    Record.defrecord(:link_filter, [filter: nil])
#    Record.defrecord(:link_filter_value, [filter: nil, path: []])
#
#    # Grab Runtime Flag
#    Record.defrecord(:runtime, [setting: nil])
#
#    # grab tool definition
#    Record.defrecord(:tool, [id: nil, handle: nil, name: nil])
#    Record.defrecord(:tool_filter, [filter: nil])
#
#    # grab directive by id or handle or by impacts lists (or references list)
#    Record.defrecord(:directive, [id: nil, handle: nil])
#    Record.defrecord(:directive_by_tag, [in: nil, not_in: nil, only: nil])
#
#    Record.defrecord(:directive_by_source, [source: nil])
#    Record.defrecord(:directive_by_impacts, [impacts: nil])
#    Record.defrecord(:directive_by_impacts_all, [impacts_all: nil])
#    Record.defrecord(:directive_by_references, [references_any: nil])
#    Record.defrecord(:directive_by_references_all, [references_all: nil])
#
#    # grab directive by id or handle
#    Record.defrecord(:setting, [name: nil])
#    Record.defrecord(:safety_setting, [name: nil])
#    Record.defrecord(:model_setting, [name: nil])
#    Record.defrecord(:provider_setting, [provider: nil, name: nil])
#
#
#
#    # Force invalidation / Ignore - special methods
#    Record.defrecord(:ttl, [expiry: 300])
#    # Values will be converted to the lowest specified unit. So setting day 5, hour 4 will invalidate every 5 * 24 + 4 hours.
#    Record.defrecord(:time_bucket, [years: nil, months: nil, days: nil, hours: nil, seconds: nil])
#    def dynmaic_node(), do: {:__genai__, :dynamic}
#    def finger_print(value, as \\ :auto), do: {{:__genai__, :finger_print, as}, value}
#    def no_finger_print(value), do: {{:__genai__, :no_finger_print}, value}

end