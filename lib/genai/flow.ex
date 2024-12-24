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
    last_link: nil,
    nodes: %{},
    handles: %{},
    links: %{},
    settings: nil,
  ]
  defnodetype [
    head: T.node_id | nil,
    last_node: T.node_id | nil,
    last_link: nil,
    nodes: nodes,
    handles: handles,
    links: links,
    settings: keyword(),
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
  def new(id, options) do
    id = if id == :auto, do: UUID.uuid4(), else: id
    %GenAI.Flow{
      id: id,
      settings: options
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
  # head/1
  #========================================
  def head(flow) do
    case flow.head do
      nil -> {:error, {:head, :not_found}}
      head -> __MODULE__.node(flow, head)
    end
  end

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

  ## Add a new node with auto_linking - defaults
      iex> require GenAI.Flow.Records
      ...> flow = GenAI.Flow.new(:test_flow, [auto_link: true])
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_a))
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_b))
      ...> last_link = flow.last_link
      ...> flow
      %GenAI.Flow{id: :test_flow, head: :test_node_a, last_node: :test_node_b, nodes: %{:test_node_a => %GenAI.Flow.Node{id: :test_node_a}, :test_node_b => %GenAI.Flow.Node{id: :test_node_b}}, links: %{^last_link => %GenAI.Flow.Link{source: R.link_source(id: :test_node_a, outlet: :default), target: R.link_target(id: :test_node_b, inlet: :default)}}} = flow

  ## Add a new node with auto_linking (custom)
      iex> require GenAI.Flow.Records
      ...> flow = GenAI.Flow.new(:test_flow, [auto_link: GenAI.Flow.Link.new(R.link_source(id: nil, outlet: :auto), R.link_target(id: nil, inlet: :auto), id: :auto)])
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_a))
      ...> |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_b))
      ...> last_link = flow.last_link
      ...> flow
      %GenAI.Flow{id: :test_flow, head: :test_node_a, last_node: :test_node_b, nodes: %{:test_node_a => %GenAI.Flow.Node{id: :test_node_a}, :test_node_b => %GenAI.Flow.Node{id: :test_node_b}}, links: %{^last_link => %GenAI.Flow.Link{source: R.link_source(id: :test_node_a, outlet: :auto), target: R.link_target(id: :test_node_b, inlet: :auto)}}} = flow
  """
  @spec add_node(flow :: t, node :: T.flow_node, T.options) :: t
  def add_node(flow, node, options \\ nil) do
    last_node = cond do
      flow.last_node -> flow.last_node
      options[:auto_head] == false -> flow.last_node
      flow.settings[:auto_head] == false -> flow.last_node
      :else -> {:external, :unbound}
    end

    with {:ok, id} <- GenAI.Flow.Node.id(node) do
      cond do
        member?(flow, id) ->
          cond do
            options[:replace] ->
              raise GenAI.Flow.Exception,
                    message: "Replace option not yet implemented"
            :else ->
              raise GenAI.Flow.Exception,
                    message: "Node with #{id} already defined in flow"
          end
        flow.head ->
          flow
          |> put_in([Access.key(:nodes), id], node)
          |> put_in([Access.key(:last_node)], id)
        options[:auto_head] == false ->
          flow
          |> put_in([Access.key(:nodes), id], node)
          |> put_in([Access.key(:last_node)], id)
        :auto_head ->
          flow
          |> put_in([Access.key(:nodes), id], node)
          |> put_in([Access.key(:last_node)], id)
          |> put_in([Access.key(:head)], id)
      end
      |> then(
           fn
             flow ->
               auto_link = cond do
                 options[:link] == false -> false
                 options[:link] == nil -> flow.settings[:auto_link]
                 options[:link] == :default -> flow.settings[:auto_link] || false
                 options[:link] == true -> flow.settings[:auto_link] || true
                 is_atom(options[:link]) -> flow.settings[:auto_link_templates][options[:link]] || flow.settings[:auto_link]
                :else -> options[:link]
               end

               case auto_link do
                 nil -> flow
                 false -> flow
                 true ->
                   if last_node do
                     link = GenAI.Flow.Link.new(last_node, id)
                     flow
                     |> GenAI.Flow.add_link(link)
                   else
                     flow
                   end
                 link_or_options ->
                  cond do
                    GenAI.Flow.LinkProtocol.impl_for(link_or_options) ->
                      if last_node do
                        link = link_or_options
                        link = with {:ok, link} <- GenAI.Flow.LinkProtocol.bind_source(link, last_node) do
                          link
                        else
                          _ -> link
                        end
                        link = with {:ok, link} <- GenAI.Flow.LinkProtocol.bind_target(link, id) do
                          link
                        else
                          _ -> link
                        end
                        {:ok, link} = GenAI.Flow.LinkProtocol.with_id(link)
                        flow
                        |> GenAI.Flow.add_link(link)
                      else
                        flow
                      end
                    not(is_struct(link_or_options)) and (is_map(link_or_options) or is_list(link_or_options)) ->
                      if last_node do
                        link = GenAI.Flow.Link.new(last_node, id, link_or_options)
                        flow
                        |> GenAI.Flow.add_link(link)
                      else
                        flow
                      end
                  end
               end
           end
         )
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
         true <- (member?(flow, source) or Kernel.match?({:external, _}, source)) || {:error, "Source node #{inspect source} not defined in flow"},
         true <- (member?(flow, target) or Kernel.match?({:external, _}, target)) || {:error, "Target node #{inspect target} not defined in flow"},
         true <- not(Map.has_key?(flow.links, link_id)) || {:error, "Link with #{link_id} already defined in flow"} do

      # Add link to list of edges.
      flow
      |> put_in([Access.key(:links), link_id], link)
      |> put_in([Access.key(:last_link)], link_id)
        # Update source and target node
      |> then(
           fn
             flow ->
               case source do
                 {:external, _} -> flow
                 {:unbound} -> flow
                 _ ->
                   {:ok, n} = __MODULE__.node(flow, source)
                   {:ok, n} = n
                              |> GenAI.Flow.NodeProtocol.register_link(link)

                   flow
                   |> put_in([Access.key(:nodes), source], n)
               end
           end)
      |> then(
           fn
             flow ->
               case source do
                 {:target, _} -> flow
                 {:unbound} -> flow
                 _ ->
                   {:ok, n} = __MODULE__.node(flow, target)
                   {:ok, n} = n
                              |> GenAI.Flow.NodeProtocol.register_link(link)
                   flow
                   |> put_in([Access.key(:nodes), target], n)
               end
           end)
    else
      {:error, e} ->
        raise GenAI.Flow.Exception,
              message: "Link Error: #{inspect e}"
    end
  end # end of GenAI.Flow.add_link

end # end of GenAI.Flow


defimpl GenAI.Thread.NodeProtocol, for: GenAI.Flow do
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R

  defp entry_point(node, link, container, state, options) do
    # @todo support incoming external links from container into specific flow.node
    # todo deal with nesting/incoming link/entry point
    # {:ok, R.flow_advance(node: node)}

  end

  @doc """
  Process node in flow (update state/effective settings, run any interstitial inference, etc.).
  """
  def process_node(node, link, container, state, options)
  def process_node(node, link, container, state, options) do
    {:error, R.flow_error(details: "Not yet implemented")}
  end
end
