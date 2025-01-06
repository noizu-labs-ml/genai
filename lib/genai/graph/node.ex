defmodule GenAI.Graph.Node do
  @vsn 1.0
  @moduledoc """
  Represent a node on graph (generic type).
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
               inbound_links: map(),
               outbound_links: map(),
               vsn: float()
             }

  defstruct [
    id: nil,
    handle: nil,
    name: nil,
    description: nil,
    inbound_links: %{},
    outbound_links: %{},


    vsn: @vsn
  ]

  @doc """
  Create a new node.
  """
  def new(options \\ nil) do
    %__MODULE__{
      id: options[:id] || UUID.uuid4(),
      handle: options[:handle] || nil,
      name: options[:name] || nil,
      description: options[:description] || nil,
      inbound_links: %{},
      outbound_links: %{},
    }
  end

  #=============================================================================
  # Node Protocol
  #=============================================================================

  #-------------------------
  # id/1
  #-------------------------
  def id(graph_node)
  def id(%__MODULE__{id: nil}), do: {:error, {:id, :is_nil}}
  def id(%__MODULE__{id: id}), do: {:ok, id}

  #-------------------------
  # handle/1
  #-------------------------
  def handle(graph_node)
  def handle(%__MODULE__{handle: nil}), do: {:error, {:handle, :is_nil}}
  def handle(%__MODULE__{handle: handle}), do: {:ok, handle}

  #-------------------------
  # handle/2
  #-------------------------
  def handle(graph_node, default)
  def handle(%__MODULE__{handle: nil}, default), do: {:ok, default}
  def handle(%__MODULE__{handle: handle}, _), do: {:ok, handle}

  #-------------------------
  # name/1
  #-------------------------
  def name(graph_node)
  def name(%__MODULE__{name: nil}), do: {:error, {:name, :is_nil}}
  def name(%__MODULE__{name: name}), do: {:ok, name}

  #-------------------------
  # name/2
  #-------------------------
  def name(graph_node, default)
  def name(%__MODULE__{name: nil}, default), do: {:ok, default}
  def name(%__MODULE__{name: name}, _), do: {:ok, name}


  #-------------------------
  # description/1
  #-------------------------
  def description(graph_node)
  def description(%__MODULE__{description: nil}), do: {:error, {:description, :is_nil}}
  def description(%__MODULE__{description: description}), do: {:ok, description}

  #-------------------------
  # description/2
  #-------------------------
  def description(graph_node, default)
  def description(%__MODULE__{description: nil}, default), do: {:ok, default}
  def description(%__MODULE__{description: description}, _), do: {:ok, description}


  #-------------------------
  # with_id/1
  #-------------------------
  def with_id(graph_node) do
    cond do
      graph_node.id == nil ->
        graph_node
        |> put_in([Access.key(:id)], UUID.uuid4())
      graph_node.id == :auto ->
        graph_node
        |> put_in([Access.key(:id)], UUID.uuid4())
      :else -> graph_node
    end
    |> then(& {:ok, &1})
  end

  #-------------------------
  # register_link/4
  #-------------------------
  def register_link(graph_node, _graph, link, _options)
  def register_link(graph_node, _graph, link, _options) do
    with {:ok, link_id} <- GenAI.Graph.LinkProtocol.id(link),
         {:ok, source} <- GenAI.Graph.LinkProtocol.source_connector(link),
         {:ok, target} <- GenAI.Graph.LinkProtocol.target_connector(link) do

      # 1. For Source Node
      graph_node = if (R.connector(source, :node) == graph_node.id) do
        update_in(graph_node, [Access.key(:outbound_links), R.connector(source, :socket)], &([link_id | (&1 || [])] |> Enum.uniq()))
      else
        graph_node
      end

      # 2. For Target Node
      graph_node = if (R.connector(target, :node) == graph_node.id) do
        update_in(graph_node, [Access.key(:inbound_links), R.connector(target, :socket)], &([link_id | (&1 || [])] |> Enum.uniq()))
      else
        graph_node
      end

      {:ok, graph_node}
    end
  end
end



defimpl GenAI.Graph.NodeProtocol, for: GenAI.Graph.Node do
  @handler GenAI.Graph.Node
  defdelegate id(graph_link), to: @handler

  defdelegate handle(graph_link), to: @handler
  defdelegate handle(graph_link, default), to: @handler

  defdelegate name(graph_link), to: @handler
  defdelegate name(graph_link, default), to: @handler

  defdelegate description(graph_link), to: @handler
  defdelegate description(graph_link, default), to: @handler

  defdelegate with_id(graph_link), to: @handler

  defdelegate register_link(graph_node, graph, link, options), to: @handler
end