defmodule GenAI.Graph.Link.Records do
  alias GenAI.Graph.Types, as: G

  require Record
  Record.defrecord(:connector, [node: nil, socket: nil, external: false])

  @type connector :: record(:connector, node: G.graph_node_id, socket: term, external: atom)
end