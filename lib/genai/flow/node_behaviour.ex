

defmodule GenAI.Flow.Records do
  require Record
  Record.defrecord(:flow_update, node: nil, edges: nil, graph: nil, state: nil)
  Record.defrecord(:flow_advance, outbound: [], update: {:flow_update, node: nil, edges: nil, graph: nil, state: nil})
  Record.defrecord(:flow_end, update:  {:flow_update, node: nil, edges: nil, graph: nil, state: nil})
  Record.defrecord(:flow_error, details: nil, update:  {:flow_update, node: nil, edges: nil, graph: nil, state: nil})


  @type graph_node :: struct()
  @type id :: term
  @type handle :: term
  @type content :: any
  @type details :: tuple | atom | String.t
  @type edge :: struct()
  @type edges :: list(edge)
  @type edge_map :: %{outlet :: term => %{id => edge}}
  @type graph :: GenAI.Flow.t
  @type node_state :: any
  @type flow_state :: any
  @type options :: Keyword.t | Map.t | nil

  @type flow_update :: record(:flow_update, node: node, edges: edges, graph: graph, state: flow_state)
  @type flow_advance :: record(:flow_advance, outbound: edges, update: flow_update)
  @type flow_end :: record(:flow_end, update: flow_update)
  @type flow_error :: record(:flow_error, details: details, update: flow_update)

  @type flow_apply_responses :: flow_advance | flow_end | flow_error
end

defmodule GenAI.Flow.NodeBehaviour do
  require GenAI.Flow.Records
  import GenAI.Flow.Records

  @type graph_node :: struct()
  @type id :: term
  @type handle :: term
  @type content :: any
  @type details :: tuple | atom | String.t
  @type edge :: struct()
  @type edges :: list(edge)
  @type edge_map :: %{outlet :: term => %{id => edge}}
  @type graph :: GenAI.Flow.t
  @type node_state :: any
  @type flow_state :: any
  @type options :: Keyword.t | Map.t | nil

  # Access
  @callback id(graph_node) :: {:ok, id} | {:error, details}
  @callback handle(graph_node) :: {:ok, handle} | {:error, details}
  @callback content(graph_node) :: {:ok, content} | {:error, details}
  @callback state(graph_node) :: {:ok, node_state} | {:error, details}
  @callback inbound_edges(graph_node, graph) :: {:ok, edge_map} | {:error, details}
  @callback outbound_edges(graph_node, graph) :: {:ok, edge_map} | {:error, details}

  # Mutate
  @callback add_link(graph_node, edge) :: graph_node

  # Mutate State
  @callback apply(graph_node, inbound :: edge, graph, flow_state, options) :: GenAI.Flow.Records.flow_apply_responses

  # Default Implementations
  #========================================
  # id/1
  #========================================
  def id(node) do
    if node.id do
      {:ok, node.id}
    else
      {:error, {:id, :blank}}
    end
  end # end of GenAI.Flow.NodeBehaviour.id/1

  #========================================
  # handle/1 (Default)
  #========================================
  def handle(node) do
    if node.handle do
      {:ok, node.handle}
    else
      {:error, {:handle, :blank}}
    end
  end # end of GenAI.Flow.NodeBehaviour.handle/1

  #========================================
  # content/1 (Default)
  #========================================
  def content(_node = %{content: value}) do
    # null is acceptable for state
      {:ok, value}
  end
  def content(node) do
    raise GenAI.Flow.Exception,
          message: "#{node.__struct__} requires a custom implementation of GenAI.Flow.NodeBehaviour.content/1"
  end # end of GenAI.Flow.NodeBehaviour.content/1

  #========================================
  # state/1 (Default)
  #========================================
  def state(_node = %{state: value}) do
    # null is acceptable for state
    {:ok, value}
  end
  def state(node) do
    raise GenAI.Flow.Exception,
          message: "#{node.__struct__} requires a custom implementation of GenAI.Flow.NodeBehaviour.state/1"
  end

  #========================================
  # fetch_edges/2
  #========================================
  defp do_fetch_edges(edges, graph) do
    edges = Enum.map(edges,
              fn
                {inlet_outlet, edge_ids} ->
                  edges = Enum.map(edge_ids,
                            fn edge_id ->
                              with {:ok, edge} <- GenAI.Flow.edge(graph, edge_id) do
                                {edge_id, edge}
                              else
                                {:error, details} ->
                                  raise GenAI.Flow.Exception,
                                        message: "Edge lookup failed",
                                        details: details
                              end
                            end
                          ) |> Map.new()

                  {inlet_outlet, edges}
              end
            )
            |> Map.new()
    {:ok, edges}
  end

  #========================================
  # inbound_edges/2 (Default)
  #========================================
  def inbound_edges(node, graph) do
    do_fetch_edges(node.inbound_edges, graph)
  end # end of GenAI.Flow.NodeBehaviour.inbound_edges/2

  #========================================
  # outbound_edges/2 (Default)
  #========================================
  def outbound_edges(node, graph) do
    do_fetch_edges(node.outbound_edges, graph)
  end # end of GenAI.Flow.NodeBehaviour.outbound_edges/2

  #========================================
  # add_link/2 (Default)
  #========================================
  def add_link(node, link) do
    cond do
      node.id == link.source ->
        outlet = link.source_outlet || :default
        update_in(node, [Access.key(:outbound_edges), outlet], & [link.id | (&1 || [])])

      node.id == link.target ->
        inlet = link.target_inlet || :default
        update_in(node, [Access.key(:inbound_edges), inlet], & [link.id | (&1 || [])])
    end
  end # end of GenAI.Flow.NodeBehaviour.add_link/2

  #========================================
  # apply/5 (Default)
  #========================================
  @doc """
  Default implementation of apply/5
  You generally will want to extend this for each node type.

  ---
  # Note
  Side Effects this method may alter flow_state, the flow graph and edges in said graph as well as the node itself.
  """
  def apply(node, inbound_edge, graph, flow_state, options) do
    outbound = GenAI.Flow.NodeProtocol.outbound_edges(node, graph)
               |> Enum.map(fn {outlet, edges} -> Map.values(edges) end)
               |> List.flatten()

    case outbound do
      [] ->
        Logger.info("Generic Node - Flow End (Please override this method in your node implementation)")
        flow_end()
      outbound when is_list(outbound) ->
        # @TODO set any ephemeral outbound link state needed and update state object etc as needed. (SIDE EFFECTS)
        # @TODO pick the appropriate next node. A chat flow with edited/alternative messages for example may have an internal state field indicating the currently selected node.
        # @TODO clarify what state may mutate in flow and what is mutated in flow state.
        Logger.info("Generic Node - Flow Advance (Please override this method in your node implementation)")
        flow_advance(outbound: outbound)
    end
  end # end of GenAI.Flow.NodeBehaviour.apply/5




  #========================================
  # Using Macro
  #========================================
  defmacro __using__(_opts) do
    quote do
      @behaviour GenAI.Flow.NodeBehaviour
      require GenAI.Flow.Records
      import GenAI.Flow.Records

      @impl GenAI.Flow.NodeBehaviour
      defdelegate id(node), to: GenAI.Flow.NodeBehaviour

      @impl GenAI.Flow.NodeBehaviour
      defdelegate handle(node), to: GenAI.Flow.NodeBehaviour

      @impl GenAI.Flow.NodeBehaviour
      defdelegate content(node), to: GenAI.Flow.NodeBehaviour

      @impl GenAI.Flow.NodeBehaviour
      defdelegate state(node), to: GenAI.Flow.NodeBehaviour

      @impl GenAI.Flow.NodeBehaviour
      defdelegate inbound_edges(node, graph), to: GenAI.Flow.NodeBehaviour

      @impl GenAI.Flow.NodeBehaviour
      defdelegate outbound_edges(node, graph), to: GenAI.Flow.NodeBehaviour

      @impl GenAI.Flow.NodeBehaviour
      defdelegate add_link(node, link), to: GenAI.Flow.NodeBehaviour

      @impl GenAI.Flow.NodeBehaviour
      defdelegate apply(node, inbound_edge, graph, flow_state, options), to: GenAI.Flow.NodeBehaviour

      defoverridable [
        id: 1,
        handle: 1,
        content: 1,
        state: 1,
        inbound_edges: 2,
        outbound_edges: 2,
        add_link: 2,
        apply: 5
      ]
    end
  end # end of GenAI.Flow.NodeBehaviour.__using__/1



end # end of GenAI.Flow.NodeBehaviour

