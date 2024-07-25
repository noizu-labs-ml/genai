defimpl GenAi.Graph.NodeProtocol, for: GenAI.Graph.ToolNode do
  def apply(node, state)
  def apply(node, state) do
    GenAI.Thread.StateProtocol.with_tool(state, node.content)
  end
end
