defmodule GenAI.Graph.Link.Records do
  alias GenAI.Graph.Types, as: G

  require Record
  Record.defrecord(:connector, [node: nil, plug: nil, external: false])

  @type connector :: record(:connector, node: G.graph_node_id, plug: term, external: atom)
end