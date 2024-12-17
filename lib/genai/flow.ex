defmodule GenAI.Flow do
  @vsn 1.0
  @moduledoc """
  Low Level Graph Library used by higher level structures for encoding chat threads and completions.
  """

  @typedoc """
  A uuid identifier
  """
  @type uuid :: bitstring

  @typedoc """
  Flow identifier (as flow can be nested this id follows the same conventions as a node id)
  """
  @type id :: atom | uuid | tuple | integer | bitstring

  @typedoc """
  Entry point of flow.
  """
  @type head :: id

  @typedoc """
  Map of vertices by id.
  """
  @type vertices :: %{id => any}

  @typedoc """
  A vertix alias/handle
  """
  @type handle :: id

  @typedoc """
  Map of handles by id.
  """
  @type handles :: %{handle => id}

  @typedoc """
  Flow struct version number
  """
  @type vsn :: float

  @type t :: %__MODULE__{
               id: id,
               head: head,
               vertices: vertices,
               handles: handles,
               edges: Map.t,
               vertex_edges: Map.t,
               outbound_edges: %{any => any},
               inbound_edges: %{any => any},
               vsn: vsn
             }


  @derive GenAI.Flow.NodeProtocol
  defstruct [
    id: nil,
    head: nil,
    vertices: %{},
    handles: %{},
    edges: %{},
    vertex_edges: %{},
    outbound_edges: %{}, # edge ids grouped by outlet
    inbound_edges: %{}, # edge ids grouped by inlet
    vsn: @vsn
  ]

  #========================================
  # new/1
  #========================================
  @doc """
  Creates a new flow.

  # Example
  ## Create a new flow with a random id
      iex> flow = GenAI.Flow.new()
      %GenAI.Flow{id: flow.id}

  ## Create a new flow with specified id
      iex> GenAI.Flow.new(id: :flow_1)
      %GenAI.Flow{id: :flow_1}
  """
  @spec new(options :: nil | Map.t) :: t
  def new(options \\ nil)
  def new(options) do
    id = options[:id] || GenAI.UUID.new()
    %GenAI.Flow{
      id: id
    }
  end # end of GenAI.Flow.new/1

  #========================================
  # member?/2
  #========================================
  @doc """
  Check if node defined in flow.

  # Examples
  ## Check existing node
      iex> flow = GenAI.Flow.new(id: :test_flow) |> GenAI.Flow.add_vertex(GenAI.Flow.Node.new(:test_node))
      ...> GenAI.Flow.member?(flow, :test_node)
      true

  ## Check non-existing node
      iex> flow = GenAI.Flow.new(id: :test_flow) |> GenAI.Flow.add_vertex(GenAI.Flow.Node.new(:test_node))
      ...> GenAI.Flow.member?(flow, :non_existing_node)
      false
  """
  @spec member?(flow :: t, node_or_id :: any) :: boolean
  def member?(flow, node) when is_atom(node) or is_integer(node) or is_tuple(node) or is_binary(node) do
    Map.has_key?(flow.vertices, node)
  end
  def member?(flow, node) when is_struct(node) do
    {:ok, id} = GenAI.Flow.Node.id(node)
    Map.has_key?(flow.vertices, id)
  end # end of GenAI.Flow.member?/2

  #========================================
  # node/2
  #========================================
  @doc """
  Returns the node from the flow by id.

  # Examples
  ## Get existing node
      iex> flow = GenAI.Flow.new(id: :test_flow) |> GenAI.Flow.add_vertex(GenAI.Flow.Node.new(:test_node))
      ...> GenAI.Flow.node(flow, :test_node)
      {:ok, %GenAI.Flow.Node{id: :test_node}}
  """
  @spec node(flow :: t, id :: any) :: any | nil
  def node(flow, id) when is_atom(id) or is_integer(id) or is_tuple(id) or is_binary(id) do
    if node = flow.vertices[id] do
      {:ok, node}
    else
      {:error, {:node, :not_found}}
    end
  end
  def node(flow, node) when is_struct(node) do
    {:ok, id} = GenAI.Flow.Node.id(node)
    if node = flow.vertices[id] do
      {:ok, node}
    else
      {:error, {:node, :not_found}}
    end
  end # end of GenAI.Flow.node/2

  #========================================
  # add_vertex/2
  #========================================
  @doc """
  Adds a node to the flow.

  # Examples
  ## Add a new node
      iex> flow = GenAI.Flow.new(id: :test_flow)
      ...> flow |> GenAI.Flow.add_vertex(GenAI.Flow.Node.new(:test_node))
      %GenAI.Flow{id: :test_flow, vertices: %{:test_node => %GenAI.Flow.Node{id: :test_node}}}
  """
  @spec add_vertex(flow :: t, node :: any) :: t
  def add_vertex(flow, node) do
    {:ok, id} = GenAI.Flow.Node.id(node)
    unless member?(flow, id) do
      flow
      |> put_in([Access.key(:vertices), id], node)
    else
      raise GenAI.Flow.Exception,
            message: "Node with #{id} already defined in flow"
    end
  end # end of GenAI.Flow.add_vertex

  #========================================
  # add_edge/2
  #========================================
  @doc """
  Adds a link to the flow.

  # Examples
  ## Add a new link
      iex> flow = GenAI.Flow.new(id: :test_flow)
      ...> flow = GenAI.Flow.add_vertex(flow, GenAI.Flow.Node.new(:test_node_a))
      ...> flow = GenAI.Flow.add_vertex(flow, GenAI.Flow.Node.new(:test_node_b))
      ...> flow = GenAI.Flow.add_edge(flow, GenAI.Flow.Link.new(:test_node_a, :test_node_b))
      %GenAI.Flow{} = flow
  """
  @spec add_edge(flow :: t, link :: any) :: t
  def add_edge(flow, link) do
    # Guard
    unless member?(flow, link.source) do
      raise GenAI.Flow.Exception,
            message: "Source node #{link.source} not defined in flow"
    end
    unless member?(flow, link.target) do
      raise GenAI.Flow.Exception,
            message: "Target node #{link.target} not defined in flow"
    end
    if Map.has_key?(flow.edges, link.id) do
      raise GenAI.Flow.Exception,
            message: "Link with #{link.id} already defined in flow"
    end

    # Add link to list of edges.
    flow
    |> put_in([Access.key(:edges), link.id], link)
    # Update source node
    |> update_in([Access.key(:vertices), link.source], &GenAI.Flow.NodeProtocol.add_link(&1, link))
    |> update_in([Access.key(:vertices), link.target], &GenAI.Flow.NodeProtocol.add_link(&1, link))
    # Update vertex_edges lookup table
    |> update_in([Access.key(:vertex_edges), Access.key(link.source, %{}), link.target], &([link.id | (&1 || [])]))
    |> update_in([Access.key(:vertex_edges), Access.key(link.target, %{}), link.source], &([link.id | (&1 || [])]))

  end # end of GenAI.Flow.add_link


  #========================================
  # id/1
  #========================================
  @impl GenAI.Flow.NodeProtocol
  def id(node) do
    if node.id do
      {:ok, node.id}
    else
      {:error, {:id, :blank}}
    end
  end # end of GenAI.Flow.NodeProtocol.id/1

  #========================================
  # add_link/2
  #========================================
  @impl GenAI.Flow.NodeProtocol
  def add_link(node, link) do
    # determine if we are source or target
    cond do
      node.id == link.source ->
        # add link to outbound edges
        outlet = link.source_outlet || :default
        node
        |> update_in([Access.key(:outbound_edges), outlet], & [link.id | (&1 || [])])
      node.id == link.target ->
        # add link to inbound edges
        inlet = link.target_inlet || :default
        node
        |> update_in([Access.key(:inbound_edges), inlet], & [link.id | (&1 || [])])
    end
  end # end of GenAI.Flow.NodeProtocol.add_link/2
end # end of GenAI.Flow