defmodule GenAI.Graph.ModelNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    content: nil,
    vsn: @vsn
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_model(state, node.content)
    end
  end
end
