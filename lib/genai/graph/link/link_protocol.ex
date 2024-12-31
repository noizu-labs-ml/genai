defprotocol GenAI.Graph.LinkProtocol do
  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G


  @doc """
  Obtain the id of a graph link.
  """
  @spec id(graph_link :: G.graph_link) :: T.result(G.graph_link_id, T.details)
  def id(graph_link)

  def handle(graph_link)
  def name(graph_link)
  def description(graph_link)

end