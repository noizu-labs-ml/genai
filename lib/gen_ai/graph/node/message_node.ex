defmodule GenAI.Graph.MessageNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    content: nil,
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_message(state, node.content)
    end
  end
end
