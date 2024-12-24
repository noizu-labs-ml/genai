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
      type: nil,
      title: nil,
      description: nil,
      details: nil,
    ]
  )
  @type yield_type :: :node | :user_input | :system_input | atom
  @type yield_for :: record(:yield_for, ref: term, type: yield_type, title: term, description: term, details: term)


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

  Record.defrecord(:flow_end, update: nil)
  @type flow_end :: record(:flow_end, update: flow_update)

  Record.defrecord(:flow_error, details: nil, update: nil)
  @type flow_error :: record(:flow_error, details: T.details, update: flow_update)

  @type process_flow_respone :: T.result(flow_advance | flow_yield | flow_end, flow_error | T.details)
end