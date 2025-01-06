defprotocol GenAI.GraphProtocol do
  @moduledoc """
    Protocol for managing Generic Graphs.
  """

  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G


  @doc """
  Obtain the id of a graph.

  ## Examples

  ### When Set
      iex> graph = GenAI.Graph.new()
      ...> {:ok, id} = GenAI.GraphProtocol.id(graph)
      {:ok, graph.id}

  ### When Not Set
      iex> graph = GenAI.Graph.new()
      ...> |> Map.put(:id, nil)
      ...> GenAI.GraphProtocol.id(graph)
      {:error, {:id, :is_nil}}
  """
  @spec id(graph :: G.graph) :: T.result(G.graph_id, T.details)
  def id(graph)



  @doc """
  Obtain the handle of a graph.

  ## Examples

  ### When Set
      iex> graph = GenAI.Graph.new(handle: :foo)
      ...> GenAI.GraphProtocol.handle(graph)
      {:ok, :foo}

  ### When Not Set
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.handle(graph)
      {:error, {:handle, :is_nil}}
  """
  @spec handle(graph :: G.graph) :: T.result(T.handle, T.details)
  def handle(graph)

  @doc """
  Obtain the handle of a graph, or return a default value if the handle is nil.

  ## Examples

  ### When Set
      iex> graph = GenAI.Graph.new(handle: :foo)
      ...> GenAI.GraphProtocol.handle(graph, :default)
      {:ok, :foo}

  ### When Not Set
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.handle(graph, :default)
      {:ok, :default}
  """
  @spec handle(graph :: G.graph, default :: T.handle) :: T.result(T.handle, T.details)
  def handle(graph, default)


  @doc """
  Obtain the name of a graph.

  ## Examples

  ### When Set
      iex> graph = GenAI.Graph.new(name: "A")
      ...> GenAI.GraphProtocol.name(graph)
      {:ok, "A"}

  ### When Not Set
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.name(graph)
      {:error, {:name, :is_nil}}
  """
  @spec name(graph :: G.graph) :: T.result(T.name, T.details)
  def name(graph)

  @doc """
  Obtain the name of a graph, or return a default value if the name is nil.

  ## Examples

  ### When Set
      iex> graph = GenAI.Graph.new(name: "A")
      ...> GenAI.GraphProtocol.name(graph, "default")
      {:ok, "A"}

  ### When Not Set
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.name(graph, "default")
      {:ok, "default"}
  """
  @spec name(graph :: G.graph, default :: T.name) :: T.result(T.name, T.details)
  def name(graph, default)

  @doc """
  Obtain the description of a graph.

  ## Examples

  ### When Set
      iex> graph = GenAI.Graph.new(description: "B")
      ...> GenAI.GraphProtocol.description(graph)
      {:ok, "B"}

  ### When Not Set
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.description(graph)
      {:error, {:description, :is_nil}}
  """
  @spec description(graph :: G.graph) :: T.result(T.description, T.details)
  def description(graph)

  @doc """
  Obtain the description of a graph, or return a default value if the description is nil.

  ## Examples

  ### When Set
      iex> graph = GenAI.Graph.new(description: "B")
      ...> GenAI.GraphProtocol.description(graph, "default")
      {:ok, "B"}

  ### When Not Set
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.description(graph, "default")
      {:ok, "default"}
  """
  @spec description(graph :: G.graph, default :: T.description) :: T.result(T.description, T.details)
  def description(graph, default)


  @doc """
  Obtain node by id.

  ## Examples

  ### When Found
      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.GraphProtocol.add_node(graph, node)
      ...> GenAI.GraphProtocol.node(graph, node.id)
      {:ok, node}

  ### When Not Found
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.node(graph, UUID.uuid4())
      {:error, {:node, :not_found}}
  """
  @spec node(graph :: G.graph, id :: G.graph_node_id) :: T.result(G.graph_node, T.details)
  def node(graph, id)

  def nodes(graph)
  def nodes(graph, options)
  def nodes!(graph)
  def nodes!(graph, options)

  @doc """
  Obtain link by id.

  ## Examples

  ### When Found
      iex> graph = GenAI.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.GraphProtocol.add_node(graph, node1)
      ...> graph = GenAI.GraphProtocol.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id)
      ...> graph = GenAI.GraphProtocol.add_link(graph, link)
      ...> GenAI.GraphProtocol.link(graph, link.id)
      {:ok, link}

  ### When Not Found
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.link(graph, UUID.uuid4())
      {:error, {:link, :not_found}}
  """
  @spec link(graph :: G.graph, id :: G.graph_link_id) :: T.result(G.graph_link, T.details)
  def link(graph, id)


  @doc """
  Check if a node is a member of the graph.

  ## Examples

      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.GraphProtocol.add_node(graph, node)
      ...> GenAI.GraphProtocol.member?(graph, node.id)
      true

      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.member?(graph, UUID.uuid4())
      false
  """
  @spec member?(graph :: G.graph, id :: G.graph_node_id) :: boolean
  def member?(graph, id)

  @doc """
  Obtain node by handle.

  ## Examples

  ### When Found
      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4(), handle: :foo)
      ...> graph = GenAI.GraphProtocol.add_node(graph, node)
      ...> GenAI.GraphProtocol.by_handle(graph, :foo)
      {:ok, node}

  ### When Not Found
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.by_handle(graph, :foo)
      {:error, {:handle, :not_found}}
  """
  @spec by_handle(graph :: G.graph, handle :: T.handle) :: T.result(G.graph_node, T.details)
  def by_handle(graph, handle)

  @doc """
  Obtain link by handle.

  ## Examples

  ### When Found
      iex> graph = GenAI.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.GraphProtocol.add_node(graph, node1)
      ...> graph = GenAI.GraphProtocol.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id, handle: :bar)
      ...> graph = GenAI.GraphProtocol.add_link(graph, link)
      ...> GenAI.GraphProtocol.link_by_handle(graph, :bar)
      {:ok, link}

  ### When Not Found
      iex> graph = GenAI.Graph.new()
      ...> GenAI.GraphProtocol.link_by_handle(graph, :bar)
      {:error, {:handle, :not_found}}
  """
  @spec link_by_handle(graph :: G.graph, handle :: T.handle) :: T.result(G.graph_link, T.details)
  def link_by_handle(graph, handle)


  @doc """
  Add a node to the graph.

  ## Examples

      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.GraphProtocol.add_node(graph, node)
      ...> GenAI.GraphProtocol.member?(graph, node.id)
      true
  """
  @spec add_node(graph :: G.graph, node :: G.graph_node, options :: map) :: T.result(G.graph, T.details)
  def add_node(graph, node, options)
  def add_node(graph, node)

  @doc """
  Add a link to the graph.

  ## Examples

      iex> graph = GenAI.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.GraphProtocol.add_node(graph, node1)
      ...> graph = GenAI.GraphProtocol.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id)
      ...> graph = GenAI.GraphProtocol.add_link(graph, link)
      ...> GenAI.GraphProtocol.link(graph, link.id)
      {:ok, link}
  """
  @spec add_link(graph :: G.graph, link :: G.graph_link, options :: map) :: T.result(G.graph, T.details)
  def add_link(graph, link, options)
  def add_link(graph, link)





  @doc """
  Ensure the graph has an id, generating one if necessary.

  ## Examples

  ### When Already Set
      iex> graph = GenAI.Graph.new()
      ...> {:ok, graph2} = GenAI.GraphProtocol.with_id(graph)
      ...> %{was_nil: is_nil(graph.id), is_nil: is_nil(graph2.id), id_change: graph.id != graph2.id}
      %{was_nil: false, is_nil: false, id_change: false}

  ### When Not Set
      iex> graph = GenAI.Graph.new()
      ...> |> Map.put(:id, nil)
      ...> {:ok, graph2} = GenAI.GraphProtocol.with_id(graph)
      ...> %{was_nil: is_nil(graph.id), is_nil: is_nil(graph2.id), id_change: graph.id != graph2.id}
      %{was_nil: true, is_nil: false, id_change: true}
  """
  @spec with_id(graph_node :: G.graph_node) :: T.result(G.graph_node, T.details)
  def with_id(graph_node)


end