defprotocol GenAI.Graph.LinkProtocol do
  @moduledoc """
  Protocol for managing Graph Links.
  """
  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G
  alias GenAI.Graph.Link.Records, as: R

  @doc """
  Obtain the id of a graph link.

  # Examples

  ## when set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id, handle: :foo, name: "A", description: "B")
      ...> GenAI.Graph.LinkProtocol.id(l)
      {:ok, l.id}

  ## when not set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id, handle: :foo, name: "A", description: "B") |> put_in([Access.key(:id)], nil)
      ...> GenAI.Graph.LinkProtocol.id(l)
      {:error, {:id, :is_nil}}

  """
  @spec id(graph_link :: G.graph_link) :: T.result(G.graph_link_id, T.details)
  def id(graph_link)

  @doc """
  Obtain the handle of a graph link.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id, handle: :foo)
      ...> GenAI.Graph.LinkProtocol.handle(l)
      {:ok, :foo}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> GenAI.Graph.LinkProtocol.handle(l)
      {:error, {:handle, :is_nil}}

  """
  @spec handle(graph_link :: G.graph_link) :: T.result(T.handle, T.details)
  def handle(graph_link)

  @doc """
  Obtain the handle of a graph link, or return a default value if the handle is nil.

  # Examples

  ## When Set

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id, handle: :foo)
      ...> GenAI.Graph.LinkProtocol.handle(l, :default)
      {:ok, :foo}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> GenAI.Graph.LinkProtocol.handle(l, :default)
      {:ok, :default}

  """
  @spec handle(graph_link :: G.graph_link, default :: T.handle) :: T.result(T.handle, T.details)
  def handle(graph_link, default)

  @doc """
  Obtain the name of a graph link.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id, name: "A")
      ...> GenAI.Graph.LinkProtocol.name(l)
      {:ok, "A"}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> GenAI.Graph.LinkProtocol.name(l)
      {:error, {:name, :is_nil}}

  """
  @spec name(graph_link :: G.graph_link) :: T.result(T.name, T.details)
  def name(graph_link)

  @doc """
  Obtain the name of a graph link, or return a default value if the name is nil.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id, name: "A")
      ...> GenAI.Graph.LinkProtocol.name(l, "default")
      {:ok, "A"}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> GenAI.Graph.LinkProtocol.name(l, "default")
      {:ok, "default"}

  """
  @spec name(graph_link :: G.graph_link, default :: T.name) :: T.result(T.name, T.details)
  def name(graph_link, default)

  @doc """
  Obtain the description of a graph link.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id, description: "B")
      ...> GenAI.Graph.LinkProtocol.description(l)
      {:ok, "B"}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> GenAI.Graph.LinkProtocol.description(l)
      {:error, {:description, :is_nil}}

  """
  @spec description(graph_link :: G.graph_link) :: T.result(T.description, T.details)
  def description(graph_link)

  @doc """
  Obtain the description of a graph link, or return a default value if the description is nil.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id, description: "B")
      ...> GenAI.Graph.LinkProtocol.description(l, "default")
      {:ok, "B"}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> GenAI.Graph.LinkProtocol.description(l, "default")
      {:ok, "default"}

  """
  @spec description(graph_link :: G.graph_link, default :: T.description) :: T.result(T.description, T.details)
  def description(graph_link, default)

  @doc """
  Ensure the graph link has an id, generating one if necessary.

  # Examples
  ## When Already Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> {:ok, l2} = GenAI.Graph.LinkProtocol.with_id(l)
      ...> %{was_nil: is_nil(l.id), is_nil: is_nil(l2.id), id_change: l.id != l2.id}
      %{was_nil: false, is_nil: false, id_change: false}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id) |> put_in([Access.key(:id)], nil)
      ...> {:ok, l2} = GenAI.Graph.LinkProtocol.with_id(l)
      ...> %{was_nil: is_nil(l.id), is_nil: is_nil(l2.id), id_change: l.id != l2.id}
      %{was_nil: true, is_nil: false, id_change: true}

  """
  @spec with_id(graph_link :: G.graph_link) :: T.result(G.graph_link, T.details)
  def with_id(graph_link)

  @doc """
  Obtain the source connector of a graph link.

  # Examples

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> {:ok, sut} = GenAI.Graph.LinkProtocol.source_connector(l)
      ...> sut
      R.connector(external: false) = sut

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> l = GenAI.Graph.Link.new(nil, node1_id)
      ...> {:ok, sut} = GenAI.Graph.LinkProtocol.source_connector(l)
      ...> sut
      R.connector(external: true) = sut

  """
  @spec source_connector(graph_link :: G.graph_link) :: T.result(R.connector, T.details)
  def source_connector(graph_link)

  @doc """
  Obtain the target connector of a graph link.

  # Examples

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> {:ok, sut} = GenAI.Graph.LinkProtocol.target_connector(l)
      ...> sut
      R.connector(node: ^node2_id) = sut

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> l = GenAI.Graph.Link.new(node1_id, nil)
      ...> {:ok, sut} = GenAI.Graph.LinkProtocol.target_connector(l)
      ...> sut
      R.connector(external: true) = sut
  """
  @spec target_connector(graph_link :: G.graph_link) :: T.result(R.connector, T.details)
  def target_connector(graph_link)

  @doc """
  Set the target connector of a graph link, if it is not already set.

  # Examples

  ## When Not Set. By ID
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, nil)
      ...> |> GenAI.Graph.LinkProtocol.putnew_target(node2_id)
      %GenAI.Graph.Link{target: R.connector(node: ^node2_id, external: false)} = l

  ## When Not Set. By Connector
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(node1_id, nil)
      ...> |> GenAI.Graph.LinkProtocol.putnew_target(R.connector(node: node2_id, socket: :foo, external: false))
      %GenAI.Graph.Link{target: R.connector(node: ^node2_id, external: false)} = l

  ## When Set. By ID
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> node3_id = UUID.uuid5(:oid, "node-3")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> |> GenAI.Graph.LinkProtocol.putnew_target(node3_id)
      %GenAI.Graph.Link{target: R.connector(node: ^node2_id, external: false)} = l

  ## When Set. By Connector
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> node3_id = UUID.uuid5(:oid, "node-3")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> |> GenAI.Graph.LinkProtocol.putnew_target(R.connector(node: node3_id, socket: :foo, external: false))
      %GenAI.Graph.Link{target: R.connector(node: ^node2_id, external: false)} = l

  """
  @spec putnew_target(graph_link :: G.graph_link, target :: term) :: G.graph_link
  def putnew_target(graph_link, target)

  @doc """
  Set the source connector of a graph link, if it is not already set.

  # Examples

  ## When Not Set. By ID
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(nil, node2_id)
      ...> |> GenAI.Graph.LinkProtocol.putnew_source(node1_id)
      %GenAI.Graph.Link{source: R.connector(node: ^node1_id, external: false)} = l

  ## When Not Set. By Connector
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = GenAI.Graph.Link.new(nil, node2_id)
      ...> |> GenAI.Graph.LinkProtocol.putnew_source(R.connector(node: node1_id, socket: :foo, external: false))
      %GenAI.Graph.Link{source: R.connector(node: ^node1_id, socket: :foo, external: false)} = l

  ## When Set. By ID
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> node3_id = UUID.uuid5(:oid, "node-3")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> |> GenAI.Graph.LinkProtocol.putnew_source(node3_id)
      %GenAI.Graph.Link{source: R.connector(node: ^node1_id, external: false)} = l

  ## When Set. By Connector
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> node3_id = UUID.uuid5(:oid, "node-3")
      ...> l = GenAI.Graph.Link.new(node1_id, node2_id)
      ...> |> GenAI.Graph.LinkProtocol.putnew_source(R.connector(node: node3_id, socket: :foo, external: false))
      %GenAI.Graph.Link{source: R.connector(node: ^node1_id, external: false)} = l

  """
  @spec putnew_source(graph_link :: G.graph_link, source :: term) :: G.graph_link
  def putnew_source(graph_link, source)

end