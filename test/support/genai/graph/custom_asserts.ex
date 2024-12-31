defmodule GenAI.Graph.Asserts do


  defmacro is_graph(graph) do
    quote(do: GenAI.GraphProtocol.impl_for(unquote(graph)))
  end

  defmacro is_link(graph) do
    quote(do: GenAI.Graph.LinkProtocol.impl_for(unquote(graph)))
  end

  defmacro is_node(graph) do
    quote(do: GenAI.Graph.NodeProtocol.impl_for(unquote(graph)))
  end

  defmacro assert_graph(graph, [nodes: [count: expected]]) do
    quote do
      assert length(Map.keys(unquote(graph).nodes)) == unquote(expected)
    end
  end

end