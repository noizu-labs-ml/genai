defmodule GenAI.Graph do
  @vsn 1.0
  defstruct [
    nodes: [],
    vsn: @vsn
  ]
  def append_node(this, node) do
    %{this | nodes: this.nodes ++ [node]}
  end

  defimpl  GenAi.Graph.NodeProtocol do
    def apply(this, state) do
      Enum.reduce(this.nodes, {:ok, state},
        fn
          _, state = {:error, _} -> state
          node, {:ok, state} ->
            GenAi.Graph.NodeProtocol.apply(node, state)
        end
      )
    end
  end
end
