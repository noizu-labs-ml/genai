defmodule GenAI.Graph.Link do
  @vsn 1.0
  @moduledoc """
  Represent a link between two nodes in a graph.
  """

  require GenAI.Graph.Link.Records
  require GenAI.Graph.Types
  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G
  alias GenAI.Graph.Link.Records, as: R


  @type t :: %__MODULE__{
               id: G.graph_id,
               handle: T.handle,

               name: T.name,
               description: T.description,

               type: G.link_type,
               label: G.link_label,
               # @todo specifier like count, trait, direction, etc. o(5)-->1 etc. for uml.

               source: R.connector,
               target: R.connector,

               meta: nil,

               vsn: float()
             }

  defstruct [
    id: nil,
    handle: nil,
    name: nil,
    description: nil,

    type: nil,
    label: nil,

    source: nil,
    target: nil,

    meta: nil,

    vsn: @vsn
  ]


  @doc """
  Create a new link.

  # Examples

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      iex> node2_id = UUID.uuid5(:oid, "node-2")
      iex> l = GenAI.Graph.Link.new(node1_id, node2_id, name: "Hello")
      %GenAI.Graph.Link{
        handle: nil,
        name: "Hello",
        description: nil,
        source: R.connector(node: ^node1_id, socket: :default, external: false),
        target: R.connector(node: ^node2_id, socket: :default, external: false),
        vsn: 1.0
      } = l

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      iex> node2_id = UUID.uuid5(:oid, "node-2")
      iex> l = GenAI.Graph.Link.new(R.connector(node: node1_id, socket: :default, external: false), node2_id, handle: :andy)
      %GenAI.Graph.Link{
        handle: :andy,
        source: R.connector(node: ^node1_id, socket: :default, external: false),
        target: R.connector(node: ^node2_id, socket: :default, external: false),
        vsn: 1.0
      } = l

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      iex> l = GenAI.Graph.Link.new(R.connector(node: node1_id, socket: :default, external: false), nil, description: "A Node")
      %GenAI.Graph.Link{
        description: "A Node",
        source: R.connector(node: ^node1_id, socket: :default, external: false),
        target: R.connector(node: nil, socket: :default, external: true),
        vsn: 1.0
      } = l

    # from node struct (requires protocol impl)
  """
  @spec new(term, term, term) :: term
  def new(source, target, options \\ nil)
  def new(source, target, options) do
    id = options[:id] || UUID.uuid4()
    source = to_connector(source)
    target = to_connector(target)
    %GenAI.Graph.Link{
      id: id,
      handle: options[:handle],
      name: options[:name],
      description: options[:description],
      type: options[:type] || :link,
      label: options[:label],
      source: source,
      target: target,
      vsn: @vsn
    }
  end




  #=============================================================================
  # Link Protocol
  #=============================================================================

  #-------------------------
  # id/1
  #-------------------------
  def id(graph_link)
  def id(%__MODULE__{id: nil}), do: {:error, {:id, :is_nil}}
  def id(%__MODULE__{id: id}), do: {:ok, id}

  #-------------------------
  # handle/1
  #-------------------------
  def handle(graph_link)
  def handle(%__MODULE__{handle: nil}), do: {:error, {:handle, :is_nil}}
  def handle(%__MODULE__{handle: handle}), do: {:ok, handle}

  #-------------------------
  # handle/2
  #-------------------------
  def handle(graph_link, default)
  def handle(%__MODULE__{handle: nil}, default), do: {:ok, default}
  def handle(%__MODULE__{handle: handle}, _), do: {:ok, handle}

  #-------------------------
  # name/1
  #-------------------------
  def name(graph_link)
  def name(%__MODULE__{name: nil}), do: {:error, {:name, :is_nil}}
  def name(%__MODULE__{name: name}), do: {:ok, name}

  #-------------------------
  # name/2
  #-------------------------
  def name(graph_link, default)
  def name(%__MODULE__{name: nil}, default), do: {:ok, default}
  def name(%__MODULE__{name: name}, _), do: {:ok, name}


  #-------------------------
  # description/1
  #-------------------------
  def description(graph_link)
  def description(%__MODULE__{description: nil}), do: {:error, {:description, :is_nil}}
  def description(%__MODULE__{description: description}), do: {:ok, description}

  #-------------------------
  # description/2
  #-------------------------
  def description(graph_link, default)
  def description(%__MODULE__{description: nil}, default), do: {:ok, default}
  def description(%__MODULE__{description: description}, _), do: {:ok, description}


  #-------------------------
  # type/1
  #-------------------------
  def type(graph_link)
  def type(%__MODULE__{type: nil}), do: {:error, {:type, :is_nil}}
  def type(%__MODULE__{type: type}), do: {:ok, type}

  #-------------------------
  # type/2
  #-------------------------
  def type(graph_link, default)
  def type(%__MODULE__{type: nil}, default), do: {:ok, default}
  def type(%__MODULE__{type: type}, _), do: {:ok, type}

  #-------------------------
  # label/1
  #-------------------------
  def label(graph_link)
  def label(%__MODULE__{label: nil}), do: {:error, {:label, :is_nil}}
  def label(%__MODULE__{label: label}), do: {:ok, label}

  #-------------------------
  # label/2
  #-------------------------
  def label(graph_link, default)
  def label(%__MODULE__{label: nil}, default), do: {:ok, default}
  def label(%__MODULE__{label: label}, _), do: {:ok, label}



  #-------------------------
  # with_id/1
  #-------------------------
  def with_id(graph_link) do
    cond do
      graph_link.id == nil ->
        graph_link
        |> put_in([Access.key(:id)], UUID.uuid4())
      graph_link.id == :auto ->
        graph_link
        |> put_in([Access.key(:id)], UUID.uuid4())
      :else -> graph_link
    end
    |> then(& {:ok, &1})
  end

  #-------------------------
  # source_connector/1
  #-------------------------
  def source_connector(%__MODULE__{source: nil}), do: {:error, {:source, :is_nil}}
  def source_connector(%__MODULE__{source: connector}), do: {:ok, connector}

  #-------------------------
  # target_connector/1
  #-------------------------
  def target_connector(%__MODULE__{target: nil}), do: {:error, {:target, :is_nil}}
  def target_connector(%__MODULE__{target: connector}), do: {:ok, connector}

  #-------------------------
  # putnew_target/2
  #-------------------------
  def putnew_target(graph_link, R.connector(node: connector_node, socket: connector_socket, external: connector_external)) do
    x = graph_link.target || R.connector(node: nil, socket: nil, external: false)
    if (is_nil(R.connector(x, :node))) do
      %__MODULE__{
        graph_link|
        target: R.connector(
          x,
          node: connector_node,
          socket: connector_socket,
          external: connector_external
        )
      }
    else
      graph_link
    end
  end
  def putnew_target(graph_link, target) when G.is_node_id(target) do
    x = graph_link.target || R.connector(node: nil, socket: nil, external: nil)
    if (is_nil(R.connector(x, :node))) do
      %__MODULE__{
        graph_link|
        target: R.connector(
          x,
          node: R.connector(x, :node) || target,
          socket: R.connector(x, :socket) || :default,
          external: false # wip
        )
      }
    else
      graph_link
    end
  end
  def putnew_target(graph_link, target) when is_struct(target) do
    {:ok, connector_id} = GenAI.Graph.NodeProtocol.id(target)
    x = graph_link.target || R.connector(node: nil, socket: nil, external: false)
    if (is_nil(R.connector(x, :node))) do
      %__MODULE__{
        graph_link|
        target: R.connector(
          x,
          node: R.connector(x, :node) || connector_id,
          socket: R.connector(x, :socket) || :default,
          external: false # wip
        )
      }
    else
      graph_link
    end
  end

  #-------------------------
  # putnew_source/2
  #-------------------------
  def putnew_source(graph_link, R.connector(node: connector_node, socket: connector_socket, external: connector_external)) do
    x = graph_link.source || R.connector(node: nil, socket: nil, external: false)
    if (is_nil(R.connector(x, :node))) do
      %__MODULE__{
        graph_link|
        source: R.connector(
          x,
          node: connector_node,
          socket: connector_socket,
          external: connector_external
        )
      }
    else
      graph_link
    end
  end
  def putnew_source(graph_link, source) when G.is_node_id(source) do
    x = graph_link.source || R.connector(node: nil, socket: nil, external: false)
    if (is_nil(R.connector(x, :node))) do
      %__MODULE__{
        graph_link|
        source: R.connector(
          x,
          node: R.connector(x, :node) || source,
          socket: R.connector(x, :socket) || :default,
          external: false # wip
        )
      }
    else
      graph_link
    end
  end
  def putnew_source(graph_link, source) when is_struct(source) do
    {:ok, connector_id} = GenAI.Graph.NodeProtocol.id(source)
    x = graph_link.source || R.connector(node: nil, socket: nil, external: false)
    if (is_nil(R.connector(x, :node))) do
      %__MODULE__{
        graph_link|
        source: R.connector(
          x,
          node: R.connector(x, :node) || connector_id,
          socket: R.connector(x, :socket) || :default,
          external: false # wip
        )
      }
    else
      graph_link
    end
  end

  #=============================================================================
  # Internal
  #=============================================================================

  defp to_connector(R.connector() = value), do: value
  defp to_connector(nil), do: R.connector(node: nil, socket: :default, external: true)
  defp to_connector(value) when G.is_node_id(value), do: R.connector(node: value, socket: :default, external: false)
  defp to_connector(value) do
    {:ok, x} = GenAI.Graph.NodeProtocol.id(value)
    R.connector(node: x, socket: :default, external: false)
  end
end

defimpl GenAI.Graph.LinkProtocol, for: GenAI.Graph.Link do
  @handler GenAI.Graph.Link
  defdelegate id(graph_link), to: @handler

  defdelegate handle(graph_link), to: @handler
  defdelegate handle(graph_link, default), to: @handler

  defdelegate name(graph_link), to: @handler
  defdelegate name(graph_link, default), to: @handler

  defdelegate description(graph_link), to: @handler
  defdelegate description(graph_link, default), to: @handler

  defdelegate type(graph_link), to: @handler
  defdelegate type(graph_link, default), to: @handler

  defdelegate label(graph_link), to: @handler
  defdelegate label(graph_link, default), to: @handler

  defdelegate with_id(graph_link), to: @handler

  defdelegate source_connector(graph_link), to: @handler
  defdelegate target_connector(graph_link), to: @handler

  defdelegate putnew_target(graph_link, target), to: @handler
  defdelegate putnew_source(graph_link, source), to: @handler


end

