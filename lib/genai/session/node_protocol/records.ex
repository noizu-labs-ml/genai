defmodule GenAI.Session.NodeProtocol.Records do
  alias GenAI.Graph.Types, as: G
 
  require Record
  
  # Return list of any fields to update.
  Record.defrecord(:process_update, [graph_node: nil, graph_link: nil, graph_container: nil, session_state: nil, session_runtime: nil])
  @type process_update :: record(:process_update, [graph_node: any, graph_link: any, graph_container: any, session_state: any, session_runtime: any])
  
  # Standard input arg (duplicates node, useful for comparing new to old value.
  Record.defrecord(:scope, [graph_node: nil, graph_link: nil, graph_container: nil, session_state: nil, session_runtime: nil])
  @type scope :: record(:scope, [graph_node: any, graph_link: any, graph_container: any, session_state: any, session_runtime: any])
  
  # Indicates that the node should be processed next.
  Record.defrecord(:process_next, [link: nil, update: nil])
  @type process_next :: record(:process_next, [link: any, update: process_update])

  # Indicates that processing is complete.
  Record.defrecord(:process_end, [exit_on: nil, update: nil])
  @type process_end :: record(:process_end, [exit_on: any, update: process_update])

  # Yield before resuming for external response (or wait on other node completion/global state).
  Record.defrecord(:process_yield, [yield_for: nil, update: nil])
  @type process_yield :: record(:process_yield, [yield_for: any, update: process_update])
  
  # Indicates that an error has occurred.
  Record.defrecord(:process_error, [error: nil, update: nil])
  @type process_error :: record(:process_error, [error: any, update: process_update])
  
end