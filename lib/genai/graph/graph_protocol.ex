defprotocol GenAI.GraphProtocol do
  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G


  @doc """
  Obtain the id of a graph node.
  """
  @spec id(graph :: G.graph) :: T.result(G.graph_id, T.details)
  def id(graph)

  def handle(graph)
  def handle(graph, default)
  def name(graph)
  def name(graph, default)
  def description(graph)
  def description(graph, default)

  @doc """
  Obtain node by id.
  """
  @spec node(graph :: G.graph, id :: G.graph_node_id) :: T.result(G.graph_node, T.details)
  def node(graph, id)

  @doc """
  Obtain link by id.
  """
  @spec link(graph :: G.graph, id :: G.graph_link_id) :: T.result(G.graph_link, T.details)
  def link(graph, id)

  def member?(graph, id)

  def by_handle(graph, handle)
  def link_by_handle(graph, handle)

  def add_node(graph, node, options)

  def add_link(graph, link, options)

  def with_id(graph)

end