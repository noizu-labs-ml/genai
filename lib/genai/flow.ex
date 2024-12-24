#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow do
  @vsn 1.0
  @moduledoc """
  Low Level Graph Library used by higher level structures for encoding chat threads and completions.
  """
  #use GenAI.Flow.NodeBehaviour
  require GenAI.Flow.Types
  require GenAI.Flow.Records
  alias GenAI.Flow.Types, as: T
  alias GenAI.Flow.Records, as: R
  use GenAI.Flow.NodeBehaviour


  @typedoc """
  Entry point of flow.
  """
  @type head :: T.node_id | nil

  @typedoc """
  Map of vertices by id.
  """
  @type nodes :: %{T.node_id => T.flow_node}

  @typedoc """
  Map of handles by id.
  """
  @type handles :: %{T.node_handle => T.node_id}

  @typedoc """
  Map of links by id.
  """
  @type links :: %{T.link_id => T.flow_link}

  @derive GenAI.Flow.NodeProtocol
  defnode [
    head: nil,
    last_node: nil,
    nodes: %{},
    handles: %{},
    links: %{},
  ]
  defnodetype [
    head: T.node_id | nil,
    last_node: T.node_id | nil,
    nodes: nodes,
    handles: handles,
    links: links,
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
      iex> GenAI.Flow.new(:flow_1)
      %GenAI.Flow{id: :flow_1}
  """
  @spec new(T.node_id, T.options) :: t
  def new(id \\ :auto, options \\ nil)
  def new(id, _options) do
    id = if id == :auto, do: UUID.uuid4(), else: id
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
      iex> GenAI.Flow.new(:test_flow)
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node))
      ...> |> GenAI.Flow.member?(:test_node)
      true

  ## Check non-existing node
      iex> GenAI.Flow.new(:test_flow)
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node))
      ...> |> GenAI.Flow.member?(:non_existing_node)
      false
  """
  @spec member?(flow :: t, node_or_id :: T.flow_node | T.node_id) :: boolean
  def member?(flow, node)
  def member?(flow, node) when T.is_node_id(node) do
    Map.has_key?(flow.nodes, node)
  end
  def member?(flow, node) when is_struct(node) do
    with {:ok, id} <- GenAI.Flow.NodeProtocol.id(node) do
      member?(flow, id)
    end
  end # end of GenAI.Flow.member?/2

  #========================================
  # node/2
  #========================================
  @doc """
  Returns the node from the flow by id.

  # Examples
  ## Get existing node
      iex> GenAI.Flow.new(:test_flow)
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node))
      ...> |> GenAI.Flow.node(:test_node)
      {:ok, %GenAI.Flow.Node{id: :test_node}}
  """
  @spec node(flow :: t, id :: any) :: T.result(T.flow_node, {:node, :not_found})
  def node(flow, node) when T.is_node_id(node) do
    if node = flow.nodes[node] do
      {:ok, node}
    else
      {:error, {:node, :not_found}}
    end
  end
  def node(flow, node) when is_struct(node) do
    with {:ok, id} <- GenAI.Flow.NodeProtocol.id(node) do
      node(flow, id)
    end
  end # end of GenAI.Flow.node/2

  #========================================
  # link/2
  #========================================
  @doc """
  Returns the link from the flow by id.

  # Examples
  ## Get existing link
      iex> {:ok, link} = GenAI.Flow.new(:test_flow)
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_a))
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_b))
      ...> |> GenAI.Flow.add_link(GenAI.Flow.Link.new(:test_node_a, :test_node_b, id: :test_link))
      ...> |> GenAI.Flow.link(:test_link)
      ...> link
      %GenAI.Flow.Link{id: :test_link} = link
  """
  @spec link(flow :: t, link_or_id :: T.flow_link | T.link_id) :: T.result(T.flow_link, T.details)
  def link(flow, link) when T.is_link_id(link) do
    if link = flow.links[link] do
      {:ok, link}
    else
      {:error, {:link, :not_found}}
    end
  end
  def link(flow, link) when is_struct(link) do
    with {:ok, id} <- GenAI.Flow.LinkProtocol.id(link) do
      link(flow, id)
    end
  end # end of GenAI.Flow.node/2

  #========================================
  # add_node/2
  #========================================
  @doc """
  Adds a node to the flow.

  # Examples
  ## Add a new node
      iex> GenAI.Flow.new(:test_flow)
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node))
      %GenAI.Flow{id: :test_flow, head: :test_node, last_node: :test_node, nodes: %{:test_node => %GenAI.Flow.Node{id: :test_node}}}
  """
  @spec add_node(flow :: t, node :: T.flow_node) :: t
  def add_node(flow, node) do
    with {:ok, id} <- GenAI.Flow.Node.id(node) do
      unless member?(flow, id) do
        unless flow.head do
          flow
          |> put_in([Access.key(:nodes), id], node)
          |> put_in([Access.key(:head)], id)
          |> put_in([Access.key(:last_node)], id)
        else
          flow
          |> put_in([Access.key(:nodes), id], node)
          |> put_in([Access.key(:last_node)], id)
        end
      else
        raise GenAI.Flow.Exception,
              message: "Node with #{id} already defined in flow"
      end
    end
  end # end of GenAI.Flow.add_node

  #========================================
  # add_link/2
  #========================================
  @doc """
  Adds a link to the flow.

  # Examples
  ## Add a new link
      iex> require GenAI.Flow.Records
      ...> flow = GenAI.Flow.new(:test_flow)
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_a))
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_b))
      ...> |> GenAI.Flow.add_link(GenAI.Flow.Link.new(:test_node_a, :test_node_b))
      %GenAI.Flow{} = flow
  """
  @spec add_link(flow :: t, link :: any) :: t
  def add_link(flow, link) do
    with {:ok, link_id} <- GenAI.Flow.LinkProtocol.id(link),
         {:ok, R.link_source(id: source)} <- GenAI.Flow.LinkProtocol.source(link),
         {:ok, R.link_target(id: target)} <- GenAI.Flow.LinkProtocol.target(link),
         true <- member?(flow, source) || {:error, "Source node #{source} not defined in flow"},
         true <- member?(flow, source) || {:error, "Target node #{target} not defined in flow"},
         true <- not(Map.has_key?(flow.links, link_id)) || {:error, "Link with #{link_id} already defined in flow"},
         {:ok, updated_source} <- get_in(flow, [Access.key(:nodes), source])
                                  |> GenAI.Flow.NodeProtocol.register_link(link),
         {:ok, updated_target} <- get_in(flow, [Access.key(:nodes), target])
                                  |> GenAI.Flow.NodeProtocol.register_link(link) do

      # Add link to list of edges.
      flow
      |> put_in([Access.key(:links), link_id], link)
        # Update source node
      |> put_in([Access.key(:nodes), source], updated_source)
      |> put_in([Access.key(:nodes), target], updated_target)
    else
      {:error, e} ->
        raise GenAI.Flow.Exception,
              message: "Link Error: #{inspect e}"
    end
  end # end of GenAI.Flow.add_link

end # end of GenAI.Flow