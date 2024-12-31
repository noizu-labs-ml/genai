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

end