#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================
defmodule GenAI.Graph.Node.DefaultImplementation do
    
    require GenAI.Graph.Link.Records
    require GenAI.Graph.Types
    alias GenAI.Types, as: T
    alias GenAI.Graph.Types, as: G
    alias GenAI.Graph.Link.Records, as: R
    
    #-------------------------
    # with_id/1
    #-------------------------
    def with_id(graph_node) do
        cond do
            graph_node.id == nil ->
                graph_node
                |> put_in([Access.key(:id)], UUID.uuid4())
            graph_node.id == :auto ->
                graph_node
                |> put_in([Access.key(:id)], UUID.uuid4())
            :else -> graph_node
        end
        |> then(& {:ok, &1})
    end
    
    #-------------------------
    # register_link/4
    #-------------------------
    def register_link(graph_node, _graph, link, _options)
    def register_link(graph_node, _graph, link, _options) do
        with {:ok, link_id} <- GenAI.Graph.LinkProtocol.id(link),
             {:ok, source} <- GenAI.Graph.LinkProtocol.source_connector(link),
             {:ok, target} <- GenAI.Graph.LinkProtocol.target_connector(link) do
          
          # 1. For Source Node
            graph_node = if (R.connector(source, :node) == graph_node.id) do
                update_in(graph_node, [Access.key(:outbound_links), R.connector(source, :socket)], &([link_id | (&1 || [])] |> Enum.uniq()))
            else
                graph_node
            end
            
            # 2. For Target Node
            graph_node = if (R.connector(target, :node) == graph_node.id) do
                update_in(graph_node, [Access.key(:inbound_links), R.connector(target, :socket)], &([link_id | (&1 || [])] |> Enum.uniq()))
            else
                graph_node
            end
            
            {:ok, graph_node}
        end
    end
end

defmodule GenAI.Graph.NodeBehaviour do
    @moduledoc """
    Behaviour fGraph Node Elements must adhere to.
    """
    alias GenAI.Types, as: T
    alias GenAI.Graph.Types, as: G
    
    
    
    #-------------------------
    # id/1
    #-------------------------
    @callback id(G.graph_node) :: T.result(G.graph_node_id, T.details)
    
    #-------------------------
    # handle/1
    #-------------------------
    @callback handle(G.graph_node) :: T.result(T.handle, T.details)
    
    #-------------------------
    # handle/2
    #-------------------------
    @callback handle(G.graph_node, default :: T.handle) :: T.result(T.handle, T.details)
    
    #-------------------------
    # name/1
    #-------------------------
    
    @callback name(G.graph_node) :: T.result(T.name, T.details)
    
    #-------------------------
    # name/2
    #-------------------------
    @callback name(G.graph_node, default :: T.name) :: T.result(T.name, T.details)
    
    
    #-------------------------
    # description/1
    #-------------------------
    @callback description(G.graph_node) :: T.result(T.description, T.details)
    
    #-------------------------
    # description/2
    #-------------------------
    @callback description(G.graph_node, default :: T.description) :: T.result(T.description, T.details)
    
    #-------------------------
    # with_id/1
    #-------------------------
    @callback with_id(G.graph_node) :: T.result(G.graph_node, T.details)
    
    #-------------------------
    # register_link/4
    #-------------------------
    @callback register_link(G.graph_node, G.graph, G.link, G.options) :: T.result(G.graph_node, T.details)
    
    
    #==================================
    # Support Macros
    #==================================
    defmacro defnodetype(types) do
        types = Macro.expand_once(types, __CALLER__)
        members = quote do
            [
                {:id, T.node_id},
                {:handle, T.node_handle},
                {:name, T.name},
                {:description, T.description},
                unquote_splicing(types),
                {:inbound_links, T.link_map},
                {:outbound_links, T.link_map},
                {:meta, nil | map() | keyword()},
                {:vsn, float}
            ]
        end
        
        quote do
            @type t :: %__MODULE__{
                         unquote_splicing(members)
                       }
        end
    end
    
    defmacro defnodestruct(values) do
        quote do
            @vsn Module.get_attribute(__MODULE__, :vsn, 1.0)
            Kernel.defstruct [
                                 id: nil,
                                 handle: nil,
                                 name: nil,
                                 description: nil,
                             ] ++
                             (unquote(values) || []) ++
                             [
                                 outbound_links: %{}, # edge ids grouped by outlet
                                 inbound_links: %{}, # edge ids grouped by outlet
                                 vsn: @vsn,
                                 meta: nil,
                             ]
        end # end of quote
    end
    
    #==================================
    # Using Macro
    #==================================
    defmacro __using__(opts \\ nil) do
        quote do
            @behaviour GenAI.Graph.NodeBehaviour
            @handler (unquote(opts[:provider]) || GenAI.Graph.Node.DefaultImplementation)
            require GenAI.Graph.NodeBehaviour
            import GenAI.Graph.NodeBehaviour, only: [defnodestruct: 1, defnodetype: 1]
            #-------------------------
            # id/1
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            def id(graph_node)
            def id(%{__struct__: __MODULE__, id: nil}), do: {:error, {:id, :is_nil}}
            def id(%{__struct__: __MODULE__, id: id}), do: {:ok, id}
            
            #-------------------------
            # handle/1
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            def handle(graph_node)
            def handle(%{__struct__: __MODULE__, handle: nil}), do: {:error, {:handle, :is_nil}}
            def handle(%{__struct__: __MODULE__, handle: handle}), do: {:ok, handle}
            
            #-------------------------
            # handle/2
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            def handle(graph_node, default)
            def handle(%{__struct__: __MODULE__, handle: nil}, default), do: {:ok, default}
            def handle(%{__struct__: __MODULE__, handle: handle}, _), do: {:ok, handle}
            
            #-------------------------
            # name/1
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            def name(graph_node)
            def name(%{__struct__: __MODULE__, name: nil}), do: {:error, {:name, :is_nil}}
            def name(%{__struct__: __MODULE__, name: name}), do: {:ok, name}
            
            #-------------------------
            # name/2
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            def name(graph_node, default)
            def name(%{__struct__: __MODULE__, name: nil}, default), do: {:ok, default}
            def name(%{__struct__: __MODULE__, name: name}, _), do: {:ok, name}
            
            
            #-------------------------
            # description/1
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            def description(graph_node)
            def description(%{__struct__: __MODULE__, description: nil}), do: {:error, {:description, :is_nil}}
            def description(%{__struct__: __MODULE__, description: description}), do: {:ok, description}
            
            #-------------------------
            # description/2
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            def description(graph_node, default)
            def description(%{__struct__: __MODULE__, description: nil}, default), do: {:ok, default}
            def description(%{__struct__: __MODULE__, description: description}, _), do: {:ok, description}
            
            #-------------------------
            # with_id/1
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            defdelegate with_id(graph_node), to: @handler
            
            #-------------------------
            # register_link/4
            #-------------------------
            @impl GenAI.Graph.NodeBehaviour
            defdelegate register_link(graph_node, graph, link, options), to: @handler
            
            #======================================
            # Overridable
            #======================================
            defoverridable [
                id: 1,
                handle: 1,
                handle: 2,
                name: 1,
                name: 2,
                description: 1,
                description: 2,
                with_id: 1,
                register_link: 4
            ]
        end
    end


end