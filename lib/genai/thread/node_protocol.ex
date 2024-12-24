defprotocol GenAI.Thread.NodeProtocol do

  @doc """
  Process node and proceed to next step.
  """
  def process_node(node, link, container, state, options)

end