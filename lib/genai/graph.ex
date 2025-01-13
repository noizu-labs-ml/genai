defmodule GenAI.Graph do
  @vsn 1.0
  @moduledoc """
  A graph data structure for representing AI graphs, threads, conversations, uml, etc. Utility Class
  """

  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G

  require GenAI.Session.Node.Records
  alias GenAI.Session.Node.Records, as: Node
  require GenAI.Graph.Link.Records
  alias GenAI.Graph.Link.Records, as: Link


  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  @derive GenAI.Session.NodeProtocol
  defnodetype [
               nodes: %{ G.graph_node_id => G.graph_node },
               node_handles: %{ T.handle => G.graph_node_id },

               links: %{ G.graph_link_id => G.graph_link },
               link_handles: %{ T.handle => G.graph_link_id },

               head: G.graph_node_id | nil,
               last_node: G.graph_node_id | nil,
               last_link: G.graph_link_id | nil,
  ]

  defnodestruct [
    nodes: %{},
    node_handles: %{},
    links: %{},
    link_handles: %{},

    head: nil,
    last_node: nil,
    last_link: nil,

    settings: nil,
  ]
  
  def node_type(%__MODULE__{}), do: GenAI.Graph

  @doc """
  Process node and proceed to next step.
  """
  def process_node(graph_node, scope, context, options)
  def process_node(
          graph_node,
          Node.scope(
              graph_node: graph_node,
              graph_link: graph_link,
              graph_container: graph_container,
              session_state: session_state,
              session_runtime: session_runtime
          ),
          context,
          options) do
      with {:ok, head} <- GenAI.Graph.head(graph_node) do
        # Run graph and then pass back to parent container if set based on end state.
          with x <- GenAI.Session.NodeProtocol.Runner.do_process_node(
              head,
              Node.scope(
                graph_node: head,
              graph_link: nil,
                graph_container: graph_node,
                session_state: session_state,
                session_runtime: session_runtime
              ),
              context,
              options) do
              x
          end
      end
  end
  
  
  def new(options \\ nil)
  def new(options) do
    settings = Keyword.merge(
      [
        auto_head: false,
        update_last: true,
        update_last_link: false,
        auto_link: false,
      ],
      options[:settings] || []
    )

    %__MODULE__{
      id: options[:id] || UUID.uuid4(),
      handle: options[:handle] || nil,
      name: options[:name] || nil,
      description: options[:description] || nil,
      nodes: %{},
      node_handles: %{},
      links: %{},
      link_handles: %{},
      head: nil,
      last_node: nil,
      last_link: nil,
      settings: settings,
    }
  end

  def setting(%__MODULE__{settings: settings}, setting, options, default \\ nil) do
    x = options[setting]
    cond do
      is_nil(x) or x == :default ->
        x = settings[setting]
        cond do
          x == nil -> default
          :else -> x
        end
      :else -> x
    end
  end

  #=============================================================================
  # Graph Protocol
  #=============================================================================
  require GenAI.Graph.Types
  alias GenAI.Graph.Types, as: G
  require GenAI.Graph.Link.Records
  alias GenAI.Graph.Link.Records, as: R
  
  #-------------------------
  # node/2
  #-------------------------
  
  @doc """
  Obtain node by id.
  
  ## Examples
  
  ### When Found
      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.Graph.add_node(graph, node)
      ...> GenAI.Graph.node(graph, node.id)
      {:ok, node}
  
  ### When Not Found
      iex> graph = GenAI.Graph.new()
      ...> GenAI.Graph.node(graph, UUID.uuid4())
      {:error, {:node, :not_found}}
  """
  @spec node(graph :: G.graph, id :: G.graph_node_id) :: T.result(G.graph_node, T.details)
  def node(graph, graph_node)
  def node(graph, Link.connector(node: id)) do
    node(graph, id)
  end
  def node(graph, graph_node) when G.is_node_id(graph_node) do
    if x = graph.nodes[graph_node] do
      {:ok, x}
    else
      {:error, {:node, :not_found}}
    end
  end
  def node(graph, graph_node) when is_struct(graph_node) do
    with {:ok, id} <- GenAI.Graph.NodeProtocol.id(graph_node) do
      node(graph, id)
    end
  end

  #-------------------------
  # node/2
  #-------------------------
  def nodes(graph, options \\ nil)
  def nodes(graph, _) do
    nodes = Map.values(graph.nodes)
    {:ok, nodes}
  end

  #-------------------------
  # node!/2
  #-------------------------
  def nodes!(graph, options \\ nil)
  def nodes!(graph, _) do
    Map.values(graph.nodes)
  end


  #-------------------------
  # link/2
  #-------------------------
  
  @doc """
  Obtain link by id.
  
  ## Examples
  
  ### When Found
      iex> graph = GenAI.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.Graph.add_node(graph, node1)
      ...> graph = GenAI.Graph.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id)
      ...> graph = GenAI.Graph.add_link(graph, link)
      ...> GenAI.Graph.link(graph, link.id)
      {:ok, link}
  
  ### When Not Found
      iex> graph = GenAI.Graph.new()
      ...> GenAI.Graph.link(graph, UUID.uuid4())
      {:error, {:link, :not_found}}
  """
  @spec link(graph :: G.graph, id :: G.graph_link_id) :: T.result(G.graph_link, T.details)
  def link(graph, graph_link)
  def link(graph, graph_link) when G.is_link_id(graph_link) do
    if x = graph.links[graph_link] do
      {:ok, x}
    else
      {:error, {:link, :not_found}}
    end
  end
  def link(graph, graph_link) when is_struct(graph_link) do
    with {:ok, id} <- GenAI.Graph.Link.id(graph_link) do
      node(graph, id)
    end
  end

  #-------------------------
  # member?/2
  #-------------------------
  
  
  @doc """
  Check if a node is a member of the graph.
  
  ## Examples
  
      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.Graph.add_node(graph, node)
      ...> GenAI.Graph.member?(graph, node.id)
      true
  
      iex> graph = GenAI.Graph.new()
      ...> GenAI.Graph.member?(graph, UUID.uuid4())
      false
  """
  @spec member?(graph :: G.graph, id :: G.graph_node_id) :: boolean
  def member?(graph, graph_node)
  def member?(graph, graph_node) when G.is_node_id(graph_node) do
    graph.nodes[graph_node] && true || false
  end
  def member?(graph, graph_node) when is_struct(graph_node) do
    with {:ok, id} <- GenAI.Graph.NodeProtocol.id(graph_node) do
      member?(graph, id)
    end
  end

  #-------------------------
  # by_handle/2
  #-------------------------
  
  @doc """
  Obtain node by handle.
  
  ## Examples
  
  ### When Found
      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4(), handle: :foo)
      ...> graph = GenAI.Graph.add_node(graph, node)
      ...> GenAI.Graph.by_handle(graph, :foo)
      {:ok, node}
  
  ### When Not Found
      iex> graph = GenAI.Graph.new()
      ...> GenAI.Graph.by_handle(graph, :foo)
      {:error, {:handle, :not_found}}
  """
  @spec by_handle(graph :: G.graph, handle :: T.handle) :: T.result(G.graph_node, T.details)
  def by_handle(graph, handle)
  def by_handle(graph, handle) do
    if x = graph.node_handles[handle] do
      node(graph, x)
    else
      {:error, {:handle, :not_found}}
    end
  end

  #-------------------------
  # link_by_handle/2
  #-------------------------
  
  @doc """
  Obtain link by handle.
  
  ## Examples
  
  ### When Found
      iex> graph = GenAI.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.Graph.add_node(graph, node1)
      ...> graph = GenAI.Graph.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id, handle: :bar)
      ...> graph = GenAI.Graph.add_link(graph, link)
      ...> GenAI.Graph.link_by_handle(graph, :bar)
      {:ok, link}
  
  ### When Not Found
      iex> graph = GenAI.Graph.new()
      ...> GenAI.Graph.link_by_handle(graph, :bar)
      {:error, {:handle, :not_found}}
  """
  @spec link_by_handle(graph :: G.graph, handle :: T.handle) :: T.result(G.graph_link, T.details)
  def link_by_handle(graph, handle)
  def link_by_handle(graph, handle) do
    if x = graph.link_handles[handle] do
      link(graph, x)
    else
      {:error, {:handle, :not_found}}
    end
  end

  #-------------------------
  # head/1
  #-------------------------
  def head(graph)
  def head(%__MODULE__{head: nil}), do: {:error, {:head, :is_nil}}
  def head(%__MODULE__{head: x} = graph), do: node(graph, x)

  #-------------------------
  # last_node/1
  #-------------------------
  def last_node(graph)
  def last_node(%__MODULE__{last_node: nil}), do: {:error, {:last_node, :is_nil}}
  def last_node(%__MODULE__{last_node: x} = graph), do: node(graph, x)

  #-------------------------
  # last_link/1
  #-------------------------
  def last_link(graph)
  def last_link(%__MODULE__{last_link: nil}), do: {:error, {:last_link, :is_nil}}
  def last_link(%__MODULE__{last_link: x} = graph), do: link(graph, x)


  defp attempt_set_handle(graph, id, node) do
    with {:ok, handle} <- GenAI.Graph.NodeProtocol.handle(node) do
      if graph.node_handles[handle] do
        raise GenAI.Graph.Exception,
              message: "Node with handle #{handle} already defined in graph",
              details: {:handle_exists, handle}
      end
      graph
      |> put_in([Access.key(:node_handles), handle], id)
    else
      _ -> graph
    end
  end

  defp attempt_set_head(graph, id, _node, options) do
    if setting(graph, :auto_head, options, false) || options[:head] == true  do
      graph
      |> update_in([Access.key(:head)], & &1 || id)
    else
      graph
    end
  end

  defp attempt_set_last_node(graph, id, _node, options) do
    if setting(graph, :update_last, options, false) do
      graph
      |> put_in([Access.key(:last_node)], id)
    else
      graph
    end
  end

  defp auto_link_setting(graph, options) do
    case options[:link] do
      false -> false
      nil -> graph.settings[:auto_link] || false
      :default -> graph.settings[:auto_link] || false
      true -> graph.settings[:auto_link] || true
      {:template, template} ->
        if x = graph.settings[:auto_link_templates][template] do
          x
        else
          raise GenAI.Graph.Exception,
                message: "Auto Link Template #{inspect template} Not Found",
                details: {:template_not_found, template}
        end
      x -> x
    end
  end

  defp attempt_auto_link(graph, from_node, node_id, _node, options) do
    auto_link = auto_link_setting(graph, options)
    cond do
      auto_link == false ->
        graph
      auto_link == true ->
        link = GenAI.Graph.Link.new(from_node, node_id)
        graph
        |> GenAI.Graph.add_link(link, options)
      is_struct(auto_link, GenAI.Graph.Link) ->
        link = auto_link
        with {:ok, link} <- GenAI.Graph.Link.putnew_source(link, from_node),
             {:ok, link} <- GenAI.Graph.Link.putnew_target(link, node_id),
             {:ok, link} <- GenAI.Graph.Link.with_id(link) do
          graph
          |> GenAI.Graph.add_link(link,  options)
        else
          {:error, details} ->
            raise GenAI.Graph.Exception,
                  message: "Auto Link Failed",
                  details: details
        end
      not(is_struct(auto_link)) and (is_map(auto_link) or is_list(auto_link)) ->
        auto_link_options = auto_link
        link = GenAI.Graph.Link.new(from_node, node_id, auto_link_options)
        graph
        |> GenAI.Graph.add_link(link, options)
    end
  end

  def attempt_set_node(graph, node_id, graph_node, _options) do
    unless member?(graph, node_id) do
      graph
      |> put_in([Access.key(:nodes), node_id], graph_node)
    else
      raise GenAI.Graph.Exception,
            message: "Node with #{node_id} already defined in graph",
            details: {:node_exists, node_id}
    end
  end
  
  #-------------------------
  # attach_node/3
  #-------------------------
  
  @doc """
  Attach a node to the graph linked to last inserted item.
  
  ## Examples
  
      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.Graph.attach_node(graph, node)
      ...> GenAI.Graph.member?(graph, node.id)
      true
  """
  @spec attach_node(graph :: G.graph, node :: G.graph_node, options :: map) :: T.result(G.graph, T.details)
  def attach_node(graph, graph_node, options \\ nil)
  def attach_node(graph, graph_node, options) do
    options = Keyword.merge(
      [auto_head: true, update_last: true, update_last_link: true, link: true],
      options || []
    )
    add_node(graph, graph_node, options)
  end

  #-------------------------
  # add_node/3
  #-------------------------
  
  @doc """
  Add a node to the graph.
  
  ## Examples
  
      iex> graph = GenAI.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.Graph.add_node(graph, node)
      ...> GenAI.Graph.member?(graph, node.id)
      true
  """
  @spec add_node(graph :: G.graph, node :: G.graph_node, options :: map) :: T.result(G.graph, T.details)
  def add_node(graph, graph_node, options \\ nil)
  def add_node(graph, graph_node, options) do
    with {:ok, node_id} <- GenAI.Graph.NodeProtocol.id(graph_node) do
      graph
      |> attempt_set_node(node_id, graph_node, options)
      |> attempt_set_handle(node_id, graph_node)
      |> attempt_set_head(node_id, graph_node, options)
      |> attempt_set_last_node(node_id, graph_node, options)
      |> attempt_auto_link(graph.last_node, node_id, graph_node, options)
    else
      x -> x
    end
  end


  defp local_reference?(source, target) do
    if R.connector(source, :external) && R.connector(target, :external) do
      false
    else
      true
    end
  end

  #-------------------------
  # add_node/3
  #-------------------------
  
  
  @doc """
  Add a link to the graph.
  
  ## Examples
  
      iex> graph = GenAI.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.Graph.add_node(graph, node1)
      ...> graph = GenAI.Graph.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id)
      ...> graph = GenAI.Graph.add_link(graph, link)
      ...> GenAI.Graph.link(graph, link.id)
      {:ok, link}
  """
  @spec add_link(graph :: G.graph, link :: G.graph_link, options :: map) :: T.result(G.graph, T.details)
  def add_link(graph, graph_link, options \\ nil)
  def add_link(graph, graph_link, options) do
    with {:ok, link_id} <- GenAI.Graph.Link.id(graph_link),
         {:ok, source} <- GenAI.Graph.Link.source_connector(graph_link),
         {:ok, target} <- GenAI.Graph.Link.target_connector(graph_link),
         true <- local_reference?(source, target) || {:error, {:link, :local_reference_required}} do

      graph
      |> attempt_set_link(link_id, graph_link, options)
      |> attempt_set_last_link(link_id, graph_link, options)
      |> attempt_register_link(source, graph_link, options)
      |> attempt_register_link(target, graph_link, options)
    else
      {:error, details} ->
        raise GenAI.Graph.Exception,
              message: "Link Failure - #{inspect details}",
              details: details
    end
  end


  defp attempt_set_link(graph, link_id, graph_link, _options) do
    unless Map.has_key?(graph.links, link_id) do

      with {:ok, handle} <- GenAI.Graph.Link.handle(graph_link) do
        graph
        |> put_in([Access.key(:link_handles), handle], link_id)
        |> put_in([Access.key(:links), link_id], graph_link)
      else
        _ ->
          graph
          |> put_in([Access.key(:links), link_id], graph_link)
      end

    else
      raise GenAI.Graph.Exception,
            message: "Link with #{link_id} already defined in graph",
            details: {:link_exists, link_id}
    end
  end

  defp attempt_set_last_link(graph, link_id, _graph_link, options) do
    if setting(graph, :update_last_link, options, false) do
      graph
      |> put_in([Access.key(:last_link)], link_id)
    else
      graph
    end
  end

  defp attempt_register_link(graph, connector, link, options) do
    connector_node_id = R.connector(connector, :node)
    cond do
      R.connector(connector, :external) -> graph
      member?(graph, connector_node_id) ->
        n = graph.nodes[connector_node_id]
        {:ok, n} = GenAI.Graph.NodeProtocol.register_link(n, graph, link, options)
        graph
        |> put_in([Access.key(:nodes), connector_node_id], n)
      :else ->
        raise GenAI.Graph.Exception,
              message: "Node Not Found",
              details: {:source_not_found, connector}
    end
  end
  
  
  

end




defimpl GenAI.Graph.Mermaid, for: GenAI.Graph do

  
  def mermaid_id(subject) do
    GenAI.Graph.Mermaid.Helpers.mermaid_id(subject.id)
  end

  def encode(graph_element), do: encode(graph_element, [])
  def encode(graph_element, options), do: encode(graph_element, options, %{})
  def encode(graph_element, options, state) do
    case GenAI.Graph.Mermaid.Helpers.diagram_type(options) do
      :state_diagram_v2 -> state_diagram_v2(graph_element, options, state)
      x -> {:error, {:unsupported_diagram, x}}
    end
  end
  
  
  def state_diagram_v2(graph_element, options, state) do
      identifier = mermaid_id(graph_element)
      headline = """
      stateDiagram-v2
      """
      
      if graph_element.nodes == %{} do
          body = """
                 [*] --> #{identifier}
                 state "Empty Graph" as #{identifier}
                 """ |> GenAI.Graph.Mermaid.Helpers.indent()
          graph = headline <> body
          {:ok, graph}
      else
          entry_point = if head = graph_element.head do
              """
              [*] --> #{GenAI.Graph.Mermaid.Helpers.mermaid_id(head)}
              """
          else
              ""
          end
          
          # We need expanded nodes with link details
          state = update_in(state, [:container], & [graph_element | (&1 || [])])
          contents = Enum.map(graph_element.nodes,
                         fn {_, n} ->
                           GenAI.Graph.Mermaid.encode(n, options, state)
                         end)
                     |> Enum.map(fn {:ok, x} -> x end)
                     |> Enum.join("\n")
          
          body = (entry_point <> contents)
                 |> GenAI.Graph.Mermaid.Helpers.indent()
          
          graph = headline <> body
          {:ok, graph}
      
      end
  end
  
end