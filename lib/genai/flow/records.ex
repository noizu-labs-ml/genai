#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.Records do
  alias GenAI.Flow.Types, as: T
  require Record


  Record.defrecord(:link_source, id: nil, outlet: :default)
  Record.defrecord(:link_target, id: nil, inlet: :default)

  @type link_source :: record(:link_source, id: T.node_id, outlet: T.link_inlet_outlet)
  @type link_target :: record(:link_target, id: T.node_id, inlet: T.link_inlet_outlet)

#  Record.defrecord(:flow_update, node: nil, edges: nil, graph: nil, state: nil)
#  Record.defrecord(:flow_advance, outbound: [], update: {:flow_update, node: nil, edges: nil, graph: nil, state: nil})
#  Record.defrecord(:flow_end, update:  {:flow_update, node: nil, edges: nil, graph: nil, state: nil})
#  Record.defrecord(:flow_error, details: nil, update:  {:flow_update, node: nil, edges: nil, graph: nil, state: nil})
#
#  @type flow_update :: record(:flow_update, node: T.node, edges: T.edges, graph: T.graph, state: T.flow_state)
#  @type flow_advance :: record(:flow_advance, outbound: T.edges, update: flow_update)
#  @type flow_end :: record(:flow_end, update: flow_update)
#  @type flow_error :: record(:flow_error, details: T.details, update: flow_update)
#  @type apply_flow_responses :: flow_advance | flow_end | flow_error | T.error(T.details)
end