defimpl GenAi.Graph.NodeProtocol, for: GenAI.Graph.MessageNode do
  def apply(node, state)
  def apply(node, state) do
    GenAI.Thread.StateProtocol.with_message(state, node.content)
  end
end
