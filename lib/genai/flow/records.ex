#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.Records do
  alias GenAI.Flow.Types, as: T
  require Record


  Record.defrecord(
    :link_source,
    [
      id: nil,
      outlet: :default
    ]
  )
  @type link_source :: record(:link_source, id: T.node_id, outlet: T.link_inlet_outlet)

  Record.defrecord(
    :link_target,
    [
      id: nil,
      inlet: :default
    ]
  )
  @type link_target :: record(:link_target, id: T.node_id, inlet: T.link_inlet_outlet)


  #-----------------------------------
  # flow process responses
  #-----------------------------------



  Record.defrecord(
    :yield_for,
    [
      ref: nil,
      yield_point: nil,
      type: nil,
      title: nil,
      description: nil,
      timeout: :infinity,
      details: nil,
    ]
  )

  @typedoc """
  uniquely identify yield point for any inter process commounication needed.
  """
  @type yield_ref :: term
  @typedoc """
  Yield Point contains node specific details on resumption once yield condition met.
  """
  @type yield_point :: term

  @typedoc """
  Specify yield type. E.g. waiting on node to process, user input, system/api call. etc.
  """
  @type yield_type :: :node | :user_input | :system_input | atom

  @typedoc """
  Title of the yield entry.
  Primarily used when prompting for user input.
  """
  @type yield_title :: term

  @typedoc """
  Description of what we are waiting for.
  Primarily Used when prompting for user input.
  """
  @type yield_description :: term

  @typedoc """
  Yield timeout in milliseconds. :infinity for no timeout.
  """
  @type yield_timeout :: :infinity | non_neg_integer

  @typedoc """
  Yield specific details to define what we are waiting for.
  """
  @type yield_details :: term

  @type yield_for :: record(:yield_for, ref: yield_ref, yield_point: yield_point, type: yield_type, title: yield_title, description: yield_description, details: yield_details)

  Record.defrecord(
    :flow_update,
    [
      node: nil,
      container: nil,
      state: nil
    ]
  )
  @type flow_update :: record(:flow_update, node: T.node, container: any, state: T.flow_state)

  Record.defrecord(
    :flow_advance,
    [
      links: [],
      update: nil
    ]
  )
  @type flow_advance :: record(:flow_advance, links: T.flow_links, update: flow_update)

  Record.defrecord(:flow_yield, for: nil, update: nil)
  @type flow_yield :: record(:flow_yield, for: yield_for, update: flow_update)

  Record.defrecord(:flow_end, exit_point: nil, update: nil)
  @type flow_end :: record(:flow_end, exit_point: [...], update: flow_update)

  Record.defrecord(:flow_error, exit_point: nil, details: nil, update: nil)
  @type flow_error :: record(:flow_error, exit_point: [...], details: T.details, update: flow_update)

  @type process_flow_respone :: T.result(flow_advance | flow_yield | flow_end, flow_error | T.details)
end