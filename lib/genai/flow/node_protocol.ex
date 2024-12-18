defprotocol GenAI.Flow.NodeProtocol do
  @moduledoc """
This protocol defines a unified interface for interacting with nodes in a `GenAI.Flow`.

  A node in a flow is responsible for:
- Providing identification and descriptive attributes (`id`, `handle`, `content`).
- Managing internal and associated state (`state`).
- Managing inbound and outbound edges that link nodes together in a flow (`inbound_edges`, `outbound_edges`).
- Supporting operations that mutate or augment the node, such as adding new links (`add_link`).
- Applying logic to advance the flow by processing inbound edges, altering its own state,
  and determining outbound edges to follow (`apply`).

When implementing your own node type, you can `@derive GenAI.Flow.NodeProtocol` and provide
custom implementations, or rely on defaults established by `use GenAI.Flow.NodeBehaviour`.
"""

@typedoc """
Represents a node in the flow. This is typically a struct that implements
the `GenAI.Flow.NodeBehaviour` callbacks and can be derived to implement this protocol.
"""
@type graph_node :: struct()

@typedoc """
A generic identifier for a node, can be any term.
"""
@type id :: term

@typedoc """
A handle is a term that can represent a symbolic name or reference to the node.
"""
@type handle :: term

@typedoc """
Arbitrary content that the node may hold, such as data or instructions.
"""
@type content :: any

@typedoc """
Detailed error messages or info tuples.
"""
@type details :: tuple | atom | String.t

@typedoc """
Represents an edge struct linking nodes in the flow.
"""
@type edge :: struct()

@typedoc """
A map keyed by outlets/inlets with values as maps of `id => edge`.
"""
@type edge_map :: %{term() => %{id => edge}}

@typedoc """
Represents the entire graph or flow structure containing nodes and edges.
"""
@type graph :: GenAI.Flow.t

@typedoc """
Arbitrary state associated with the node.
"""
@type node_state :: any

@typedoc """
Arbitrary flow-level state that can be passed through during execution.
"""
@type flow_state :: any

@typedoc """
Options passed to `apply/5` can be keywords, maps, or nil, providing extra context or configuration.
"""
@type options :: Keyword.t | Map.t | nil

#==================================================================
# CALLBACKS
#==================================================================

@doc """
Retrieves the unique identifier of a node.

Returns:
  - `{:ok, id}` if an identifier is found.
  - `{:error, details}` if no identifier can be retrieved.
"""
@spec id(graph_node) :: {:ok, id} | {:error, details}
def id(graph_node)

@doc """
Retrieves a handle or symbolic reference for the node.

Returns:
  - `{:ok, handle}` if a handle is found.
  - `{:error, details}` if no handle is available or retrievable.
"""
@spec handle(graph_node) :: {:ok, handle} | {:error, details}
def handle(graph_node)

@doc """
Retrieves the content associated with the node.

Returns:
  - `{:ok, content}` if content exists (can be `nil` as well).
  - `{:error, details}` if retrieval fails or is unsupported.
"""
@spec content(graph_node) :: {:ok, content} | {:error, details}
def content(graph_node)

@doc """
Retrieves the state associated with the node.

Returns:
  - `{:ok, node_state}` if state is found (can be `nil`).
  - `{:error, details}` if no state is available or retrieval fails.
"""
@spec state(graph_node) :: {:ok, node_state} | {:error, details}
def state(graph_node)

@doc """
Retrieves inbound edges for a node, organized as a map of `inlets => %{edge_id => edge}`.

Returns:
  - `{:ok, edge_map}` if inbound edges are successfully retrieved.
  - `{:error, details}` if retrieval fails.
"""
@spec inbound_edges(graph_node, graph) :: {:ok, edge_map} | {:error, details}
def inbound_edges(graph_node, graph)

@doc """
Retrieves outbound edges for a node, organized as a map of `outlets => %{edge_id => edge}`.

Returns:
  - `{:ok, edge_map}` if outbound edges are successfully retrieved.
  - `{:error, details}` if retrieval fails.
"""
@spec outbound_edges(graph_node, graph) :: {:ok, edge_map} | {:error, details}
def outbound_edges(graph_node, graph)

@doc """
Adds a link (edge) to the node, either as an inbound or outbound connection depending
on the node's role (source or target) in the link.

Returns:
  - The updated node after inserting the link.
"""
@spec add_link(graph_node, edge) :: graph_node
def add_link(graph_node, edge)

@doc """
Executes the node logic when it receives an inbound edge in a given flow context. This may:
- Update the node's state.
- Determine which outbound edges to follow next.
- Potentially return a `flow_advance`, `flow_end`, or `flow_error` record to control the flow progression.

Returns one of:
  - `flow_advance` (flow continues)
  - `flow_end` (flow terminates)
  - `flow_error` (an error occurred)

  The actual record types are defined within `GenAI.Flow.NodeBehaviour` and can represent:
- `flow_advance`: Contains outbound edges and updated state.
- `flow_end`: Indicates no further outbound edges; the flow stops.
- `flow_error`: Indicates an error condition and may include error details.
"""
@spec apply(graph_node, edge, graph, flow_state, options) ::
        GenAI.Flow.NodeBehaviour.flow_advance
        | GenAI.Flow.NodeBehaviour.flow_end
        | GenAI.Flow.NodeBehaviour.flow_error
def apply(graph_node, inbound, graph, state, options)

end # end of GenAI.Flow.NodeProtocol


defimpl GenAI.Flow.NodeProtocol, for: Any do
  @moduledoc """
  Raises errors for all entities that don't implement or derive this protocol.
  """

  def id(graph_node) when is_struct(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{graph_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def id(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(graph_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def handle(graph_node) when is_struct(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{graph_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def handle(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(graph_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def content(graph_node) when is_struct(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{graph_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def content(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(graph_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def state(graph_node) when is_struct(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{graph_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def state(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(graph_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def inbound_edges(graph_node, _graph) when is_struct(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{graph_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def inbound_edges(graph_node, _graph) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(graph_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def outbound_edges(graph_node, _graph) when is_struct(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{graph_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def outbound_edges(graph_node, _graph) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(graph_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def add_link(graph_node, _link) when is_struct(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{graph_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def add_link(graph_node, _link) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(graph_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def apply(graph_node, _inbound, _graph, _state, _options) when is_struct(graph_node) do
    raise GenAI.Flow.Exception,
          message: "#{graph_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def apply(graph_node, _inbound, _graph, _state, _options) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(graph_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  defmacro __deriving__(module, _struct, _opts) do
    quote do
      defimpl GenAI.Flow.NodeProtocol, for: unquote(module) do
        def id(graph_node) do
          apply(unquote(module), :id, [graph_node])
        end

        def handle(graph_node) do
          apply(unquote(module), :handle, [graph_node])
        end

        def content(graph_node) do
          apply(unquote(module), :content, [graph_node])
        end

        def state(graph_node) do
          apply(unquote(module), :state, [graph_node])
        end

        def inbound_edges(graph_node, graph) do
          apply(unquote(module), :inbound_edges, [graph_node, graph])
        end

        def outbound_edges(graph_node, graph) do
          apply(unquote(module), :outbound_edges, [graph_node, graph])
        end

        def add_link(graph_node, link) do
          apply(unquote(module), :add_link, [graph_node, link])
        end

        def apply(graph_node, inbound, graph, state, options) do
          apply(unquote(module), :apply, [graph_node, inbound, graph, state, options])
        end
      end
    end
  end
end