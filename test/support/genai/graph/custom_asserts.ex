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
    
    defmacro graph_size(graph) do
        quote do
            (
                nodes = GenAI.GraphProtocol.nodes!(unquote(graph))
                length(nodes)
            )
        end
    end
    
    defmacro graph_constraint(item, constraint) do
        quote do
            unquote(item) == unquote(constraint)
        end
    end
    
    defmacro graph_node_handle(node, constraint) do
        quote do
            (
                {:ok, handle} = GenAI.Graph.NodeProtocol.handle(unquote(node))
                graph_constraint(handle, unquote(constraint))
            )
        end
    end
    
    defmacro graph_node(graph, constraints) do
        quote do
            (
                gn_nodes = GenAI.GraphProtocol.nodes!(unquote(graph))
                Enum.find(gn_nodes,
                    fn gn ->
                        Enum.all?(unquote(constraints),
                            fn
                              {:handle,v} ->
                                graph_node_handle(gn, v)
                            end
                        )
                    end
                )
              )
        end
    end
#
#    defmacro assert_graph(graph, [do: block]) do
#        IO.inspect(block, label: "BLOCK")
#        quote do
#            :ok
#        end
#    end
#
    
    defmacro __using__(_) do
        quote do
            require GenAI.Graph.Asserts
            import GenAI.Graph.Asserts, only: [is_graph: 1, is_link: 1, is_node: 1, graph_size: 1, graph_node: 2, graph_node_handle: 2, graph_constraint: 2]
        end
    end


end