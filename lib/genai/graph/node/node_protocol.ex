defprotocol GenAI.Graph.NodeProtocol do

  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G


  @doc """
  Obtain the id of a graph node.
  """
  @spec id(graph_node :: G.graph_node) :: T.result(G.graph_node_id, T.details)
  def id(graph_node)
  def handle(graph_node)
  def name(graph_node)
  def description(graph_node)

  def with_id(graph_node)

  def register_link(graph_node, graph, link, options)



end