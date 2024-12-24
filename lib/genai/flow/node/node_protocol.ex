#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

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
  alias GenAI.Flow.Types, as: T

  #==================================================================
  # Protocol Methods
  #==================================================================
  @doc """
  Retrieves the unique identifier of a node.

  Returns:
    - `{:ok, id}` if an identifier is found.
    - `{:error, details}` if no identifier can be retrieved.
  """
  @spec id(T.flow_node) :: T.result(T.node_id, T.details)
  def id(flow_node)

  @doc """
  Retrieves a handle or symbolic reference for the node.

  Returns:
    - `{:ok, handle}` if a handle is found.
    - `{:error, details}` if no handle is available or retrievable.
  """
  @spec handle(T.flow_node) :: T.result(T.node_handle, T.details)
  def handle(flow_node)

  #
  #@doc """
  #Retrieves the content associated with the node.
  #
  #Returns:
  #  - `{:ok, content}` if content exists (can be `nil` as well).
  #  - `{:error, details}` if retrieval fails or is unsupported.
  #"""
  #@spec content(flow_node) :: {:ok, content} | {:error, details}
  #def content(flow_node)
  #
  #@doc """
  #Retrieves the state associated with the node.
  #
  #Returns:
  #  - `{:ok, node_state}` if state is found (can be `nil`).
  #  - `{:error, details}` if no state is available or retrieval fails.
  #"""
  #@spec state(flow_node) :: {:ok, node_state} | {:error, details}
  #def state(flow_node)

  @doc """
  Retrieves inbound edges for a node, organized as a map of `inlets => %{edge_id => edge}`.

  Returns:
    - `{:ok, link_map}` if inbound edges are successfully retrieved.
    - `{:error, details}` if retrieval fails.
  """
  @spec inbound_links(T.flow_node, T.flow) :: T.result(T.link_map, T.details)
  def inbound_links(flow_node, flow)

  @doc """
  Retrieves outbound edges for a node, organized as a map of `outlets => %{edge_id => edge}`.

  Returns:
    - `{:ok, edge_map}` if outbound edges are successfully retrieved.
    - `{:error, details}` if retrieval fails.
  """
  @spec outbound_links(T.flow_node, T.flow) ::T.result(T.link_map, T.details)
  def outbound_links(flow_node, flow)


  @doc """
  Populate id if not already set.
  """
  @spec with_id(T.flow_node) :: T.result(T.flow_node, T.details)
  def with_id(flow_node)

  @doc """
  Adds a link (edge) to the node, either as an inbound or outbound connection depending
  on the node's role (source or target) in the link.

  Returns:
    - The updated node after inserting the link.
  """
  @spec register_link(T.flow_node, T.flow_link) :: T.result(T.flow_node, T.details)
  def register_link(flow_node, flow_link)



  #@doc """
  #Executes the node logic when it receives an inbound edge in a given flow context. This may:
  #- Update the node's state.
  #- Determine which outbound edges to follow next.
  #- Potentially return a `flow_advance`, `flow_end`, or `flow_error` record to control the flow progression.
  #
  #Returns one of:
  #  - `flow_advance` (flow continues)
  #  - `flow_end` (flow terminates)
  #  - `flow_error` (an error occurred)
  #
  #  The actual record types are defined within `GenAI.Flow.NodeBehaviour` and can represent:
  #- `flow_advance`: Contains outbound edges and updated state.
  #- `flow_end`: Indicates no further outbound edges; the flow stops.
  #- `flow_error`: Indicates an error condition and may include error details.
  #"""
  #@spec apply(flow_node, edge, flow, flow_state, options) ::
  #        GenAI.Flow.NodeBehaviour.flow_advance
  #        | GenAI.Flow.NodeBehaviour.flow_end
  #        | GenAI.Flow.NodeBehaviour.flow_error
  #def apply(flow_node, inbound, flow, state, options)

end # end of GenAI.Flow.NodeProtocol


defimpl GenAI.Flow.NodeProtocol, for: Any do
  @moduledoc """
  Raises errors for all entities that don't implement or derive this protocol.
  """

  def id(flow_node) when is_struct(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def id(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def handle(flow_node) when is_struct(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def handle(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  #  def content(flow_node) when is_struct(flow_node) do
  #    raise GenAI.Flow.Exception,
  #          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  #  end
  #  def content(flow_node) do
  #    raise GenAI.Flow.Exception,
  #          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  #  end
  #
  #  def state(flow_node) when is_struct(flow_node) do
  #    raise GenAI.Flow.Exception,
  #          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  #  end
  #  def state(flow_node) do
  #    raise GenAI.Flow.Exception,
  #          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  #  end

  def inbound_links(flow_node, _flow) when is_struct(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def inbound_links(flow_node, _flow) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def outbound_links(flow_node, _flow) when is_struct(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def outbound_links(flow_node, _flow) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end



  def with_id(flow_node) when is_struct(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def with_id(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end


  def register_link(flow_node, _link) when is_struct(flow_node) do
    raise GenAI.Flow.Exception,
          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def register_link(flow_node, _link) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end




  #  def apply(flow_node, _inbound, _flow, _state, _options) when is_struct(flow_node) do
  #    raise GenAI.Flow.Exception,
  #          message: "#{flow_node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  #  end
  #  def apply(flow_node, _inbound, _flow, _state, _options) do
  #    raise GenAI.Flow.Exception,
  #          message: "#{inspect(flow_node)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  #  end

  defmacro __deriving__(module, _struct, _opts) do
    quote do
      defimpl GenAI.Flow.NodeProtocol, for: unquote(module) do
        def id(flow_node) do
          apply(unquote(module), :id, [flow_node])
        end

        def handle(flow_node) do
          apply(unquote(module), :handle, [flow_node])
        end

        #        def content(flow_node) do
        #          apply(unquote(module), :content, [flow_node])
        #        end
        #
        #        def state(flow_node) do
        #          apply(unquote(module), :state, [flow_node])
        #        end

        def inbound_links(flow_node, flow) do
          apply(unquote(module), :inbound_links, [flow_node, flow])
        end

        def outbound_links(flow_node, flow) do
          apply(unquote(module), :outbound_links, [flow_node, flow])
        end

        def with_id(flow_node) do
          apply(unquote(module), :with_id, [flow_node])
        end


        def register_link(flow_node, link) do
          apply(unquote(module), :register_link, [flow_node, link])
        end

        #        def apply(flow_node, inbound, flow, state, options) do
        #          apply(unquote(module), :apply, [flow_node, inbound, flow, state, options])
        #        end
      end
    end
  end
end