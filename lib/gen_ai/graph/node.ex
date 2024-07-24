

defmodule GenAI.Graph.Node do
  @vsn 1.0
  defstruct [
    identifier: nil,
    content: nil,
    vsn: @vsn
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(_, state) do
      {:ok, state}
    end
  end
end
