defprotocol GenAI.Graph.NodeProtocol do
  @moduledoc """
  Protocol for managing Graph Nodes.
  """
  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G
  
  
  
  
  
  @doc """
  Obtain the id of a graph node.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{id: UUID.uuid4()}
      ...> GenAI.Graph.NodeProtocol.id(node)
      {:ok, node.id}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{id: nil}
      ...> GenAI.Graph.NodeProtocol.id(node)
      {:error, {:id, :is_nil}}
  """
  @spec id(graph_node :: G.graph_node) :: T.result(G.graph_node_id, T.details)
  def id(graph_node)

  @doc """
  Obtain the handle of a graph node.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{handle: :foo}
      ...> GenAI.Graph.NodeProtocol.handle(node)
      {:ok, :foo}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{handle: nil}
      ...> GenAI.Graph.NodeProtocol.handle(node)
      {:error, {:handle, :is_nil}}
  """
  @spec handle(graph_node :: G.graph_node) :: T.result(T.handle, T.details)
  def handle(graph_node)

  @doc """
  Obtain the handle of a graph node, or return a default value if the handle is nil.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{handle: :foo}
      ...> GenAI.Graph.NodeProtocol.handle(node, :default)
      {:ok, :foo}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{handle: nil}
      ...> GenAI.Graph.NodeProtocol.handle(node, :default)
      {:ok, :default}
  """
  @spec handle(graph_node :: G.graph_node, default :: T.handle) :: T.result(T.handle, T.details)
  def handle(graph_node, default)

  @doc """
  Obtain the name of a graph node.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{name: "A"}
      ...> GenAI.Graph.NodeProtocol.name(node)
      {:ok, "A"}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{name: nil}
      ...> GenAI.Graph.NodeProtocol.name(node)
      {:error, {:name, :is_nil}}
  """
  @spec name(graph_node :: G.graph_node) :: T.result(T.name, T.details)
  def name(graph_node)

  @doc """
  Obtain the name of a graph node, or return a default value if the name is nil.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{name: "A"}
      ...> GenAI.Graph.NodeProtocol.name(node, "default")
      {:ok, "A"}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{name: nil}
      ...> GenAI.Graph.NodeProtocol.name(node, "default")
      {:ok, "default"}
  """
  @spec name(graph_node :: G.graph_node, default :: T.name) :: T.result(T.name, T.details)
  def name(graph_node, default)

  @doc """
  Obtain the description of a graph node.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{description: "B"}
      ...> GenAI.Graph.NodeProtocol.description(node)
      {:ok, "B"}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{description: nil}
      ...> GenAI.Graph.NodeProtocol.description(node)
      {:error, {:description, :is_nil}}
  """
  @spec description(graph_node :: G.graph_node) :: T.result(T.description, T.details)
  def description(graph_node)

  @doc """
  Obtain the description of a graph node, or return a default value if the description is nil.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{description: "B"}
      ...> GenAI.Graph.NodeProtocol.description(node, "default")
      {:ok, "B"}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{description: nil}
      ...> GenAI.Graph.NodeProtocol.description(node, "default")
      {:ok, "default"}
  """
  @spec description(graph_node :: G.graph_node, default :: T.description) :: T.result(T.description, T.details)
  def description(graph_node, default)

  @doc """
  Ensure the graph node has an id, generating one if necessary.

  ## Examples

  ### When Already Set
      iex> node = %GenAI.Graph.Node{id: UUID.uuid4()}
      ...> {:ok, node2} = GenAI.Graph.NodeProtocol.with_id(node)
      ...> %{was_nil: is_nil(node.id), is_nil: is_nil(node2.id), id_change: node.id != node2.id}
      %{was_nil: false, is_nil: false, id_change: false}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{id: nil}
      ...> {:ok, node2} = GenAI.Graph.NodeProtocol.with_id(node)
      ...> %{was_nil: is_nil(node.id), is_nil: is_nil(node2.id), id_change: node.id != node2.id}
      %{was_nil: true, is_nil: false, id_change: true}
  """
  @spec with_id(graph_node :: G.graph_node) :: T.result(G.graph_node, T.details)
  def with_id(graph_node)

  @doc """
  Register a link with the graph node.

  ## Examples

      iex> n1 = UUID.uuid5(:oid, "node-1")
      ...> n2 = UUID.uuid5(:oid, "node-2")
      ...> n = %GenAI.Graph.Node{id: n1}
      ...> link = GenAI.Graph.Link.new(n1, n2)
      ...> link_id = link.id
      ...> {:ok, updated} = GenAI.Graph.NodeProtocol.register_link(n, %{}, link, nil)
      ...> updated
      %GenAI.Graph.Node{outbound_links: %{default: [^link_id]}} = updated
  """
  @spec register_link(graph_node :: G.graph_node, graph :: G.graph, link :: G.graph_link, options :: map) :: T.result(G.graph_node, T.details)
  def register_link(graph_node, graph, link, options)

  def outbound_links(graph_node, graph, options)
  def inbound_links(graph_node, graph, options)
end

defmodule GenAI.Graph.NodeProtocol.DefaultProvider do
    require GenAI.Graph.Link.Records
    require GenAI.Graph.Types
    alias GenAI.Types, as: T
    alias GenAI.Graph.Types, as: G
    alias GenAI.Graph.Link.Records, as: R

    #-------------------------
    # id/1
    #-------------------------
    def id(%{__struct__: module} = graph_node) do
        if Code.ensure_loaded?(module) and function_exported?(module, :id, 1) do
            module.id(graph_node)
        else
            do_id(graph_node)
        end
    end
    def do_id(graph_node)
    def do_id(%{id: nil}), do: {:error, {:id, :is_nil}}
    def do_id(%{id: id}), do: {:ok, id}
    
    #-------------------------
    # handle/1
    #-------------------------
    def handle(%{__struct__: module} = graph_node) do
        if Code.ensure_loaded?(module) and function_exported?(module, :handle, 1) do
            module.handle(graph_node)
        else
            do_handle(graph_node)
        end
    end
    def do_handle(graph_node)
    def do_handle(%{handle: nil}), do: {:error, {:handle, :is_nil}}
    def do_handle(%{handle: handle}), do: {:ok, handle}
    
    #-------------------------
    # handle/2
    #-------------------------
    def handle(%{__struct__: module} = graph_node, default) do
        if Code.ensure_loaded?(module) and function_exported?(module, :handle, 2) do
            module.handle(graph_node, default)
        else
            do_handle(graph_node, default)
        end
    end
    def do_handle(graph_node, default)
    def do_handle(%{handle: nil}, default), do: {:ok, default}
    def do_handle(%{handle: handle}, _), do: {:ok, handle}
    
    #-------------------------
    # name/1
    #-------------------------
    def name(%{__struct__: module} = graph_node) do
        if Code.ensure_loaded?(module) and function_exported?(module, :name, 1) do
            module.name(graph_node)
        else
            do_name(graph_node)
        end
    end
    def do_name(graph_node)
    def do_name(%{name: nil}), do: {:error, {:name, :is_nil}}
    def do_name(%{name: name}), do: {:ok, name}
    
    #-------------------------
    # name/2
    #-------------------------
    def name(%{__struct__: module} = graph_node, default) do
        if Code.ensure_loaded?(module) and function_exported?(module, :name, 2) do
            module.name(graph_node, default)
        else
            do_name(graph_node, default)
        end
    end
    def do_name(graph_node, default)
    def do_name(%{name: nil}, default), do: {:ok, default}
    def do_name(%{name: name}, _), do: {:ok, name}
    
    
    #-------------------------
    # description/1
    #-------------------------
    def description(%{__struct__: module} = graph_node) do
        if Code.ensure_loaded?(module) and function_exported?(module, :description, 1) do
            module.description(graph_node)
        else
            do_description(graph_node)
        end
    end
    def do_description(graph_node)
    def do_description(%{description: nil}), do: {:error, {:description, :is_nil}}
    def do_description(%{description: description}), do: {:ok, description}
    
    #-------------------------
    # description/2
    #-------------------------
    def description(%{__struct__: module} = graph_node, default) do
        if Code.ensure_loaded?(module) and function_exported?(module, :description, 2) do
            module.description(graph_node, default)
        else
            do_description(graph_node, default)
        end
    end
    def do_description(graph_node, default)
    def do_description(%{description: nil}, default), do: {:ok, default}
    def do_description(%{description: description}, _), do: {:ok, description}
    
    
    #-------------------------
    # with_id/2
    #-------------------------
    def with_id(%{__struct__: module} =graph_node) do
        if Code.ensure_loaded?(module) and function_exported?(module, :with_id, 1) do
            module.with_id(graph_node)
        else
            do_with_id(graph_node)
        end
    end
    
    def  do_with_id(graph_node) do
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
    # register_link/5
    #-------------------------
    def  register_link(%{__struct__: module} =graph_node, graph, link, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :register_link, 4) do
            module.register_link(graph_node, graph, link, options)
        else
            do_register_link(graph_node, graph, link, options)
        end
    end
    
    def  do_register_link(graph_node, _graph, link, _options) do
        with {:ok, link_id} <- GenAI.Graph.Link.id(link),
             {:ok, source} <- GenAI.Graph.Link.source_connector(link),
             {:ok, target} <- GenAI.Graph.Link.target_connector(link) do
          
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
    
    #-------------------------
    # outbound_links/4
    #-------------------------
    def  outbound_links(%{__struct__: module} =graph_node, graph, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :outbound_links, 3) do
            module.outbound_links(graph_node, graph, options)
        else
            do_outbound_links(graph_node, graph, options)
        end
    end
    
    def  do_outbound_links(graph_node, graph, options) do
        if options[:expand] do
            links = Enum.map(
                        graph_node.outbound_links,
                        fn {socket, link_ids} ->
                          links = Enum.map(link_ids,
                              fn link_id ->
                                {:ok, link} = GenAI.Graph.link(graph, link_id)
                                link
                              end
                          )
                          {socket, links}
                        end
                    )
                    |> Map.new()
            {:ok, links}
        else
            {:ok, graph_node.outbound_links}
        end
    end
    
    #-------------------------
    # inbound_links/4
    #-------------------------
    def  inbound_links(%{__struct__: module} =graph_node, graph, options) do
        if Code.ensure_loaded?(module) and function_exported?(module, :inbound_links, 3) do
            module.inbound_links(graph_node, graph, options)
        else
            do_inbound_links(graph_node, graph, options)
        end
    end
    
    def  do_inbound_links(graph_node, graph, options) do
        if options[:expand] do
            links = Enum.map(
                        graph_node.inbound_links,
                        fn {socket, link_ids} ->
                          links = Enum.map(link_ids,
                              fn link_id ->
                                {:ok, link} = GenAI.Graph.link(graph, link_id)
                                link
                              end
                          )
                          {socket, links}
                        end
                    )
                    |> Map.new()
            {:ok, links}
        else
            {:ok, graph_node.inbound_links}
        end
    end

end


defimpl GenAI.Graph.NodeProtocol, for: Any do
  def id(_), do: {:error, :unsupported}
  def handle(_), do: {:error, :unsupported}
  def handle(_,_), do: {:error, :unsupported}
  def name(_), do: {:error, :unsupported}
  def name(_,_), do: {:error, :unsupported}
  def description(_), do: {:error, :unsupported}
  def description(_,_), do: {:error, :unsupported}
  def with_id(_), do: {:error, :unsupported}
  def register_link(_,_,_,_), do: {:error, :unsupported}
  def outbound_links(_,_,_), do: {:error, :unsupported}
  def inbound_links(_,_,_), do: {:error, :unsupported}
  
  @impl true
  defmacro __deriving__(module, _struct, options) do
      quote do
          defimpl GenAI.Graph.NodeProtocol, for: unquote(module) do
              @provider (unquote(options[:provider]) || GenAI.Graph.NodeProtocol.DefaultProvider)
              
              defdelegate id(subject), to: @provider
              defdelegate handle(subject), to: @provider
              defdelegate handle(subject, default), to: @provider
              defdelegate name(subject), to: @provider
              defdelegate name(subject, default), to: @provider
              defdelegate description(subject), to: @provider
              defdelegate description(subject, default), to: @provider
              defdelegate with_id(subject), to: @provider
              defdelegate register_link(subject, graph, link, options), to: @provider
              defdelegate outbound_links(subject, graph, options), to: @provider
              defdelegate inbound_links(subject, graph, options), to: @provider
          end
      end
  end
  
end