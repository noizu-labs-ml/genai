
defmodule GenAI.Flow.Node do
  @vsn 1.0
  @moduledoc """
  Generic Flow Node
  """

  @type t :: %GenAI.Flow.Node{
               id: any,
               handle: term | nil,
               content: any,
               state: any,
               outbound_edges: %{any => any},
               inbound_edges: %{any => any},
               vsn: float,
             }

  @derive GenAI.Flow.NodeProtocol
  defstruct [
    id: nil,
    handle: nil,
    content: nil,
    state: nil,
    outbound_edges: %{}, # edge ids grouped by outlet
    inbound_edges: %{}, # edge ids grouped by inlet
    vsn: @vsn,
  ]

  #========================================
  # new/1
  #========================================
  @doc """
  Create a new flow node
  """
  @spec new(id :: term, content :: any, options :: nil | Map.t) :: GenAI.Flow.Node.t
  def new(id, content \\ nil, options \\ nil)
  def new(id, content, _options) do
    %GenAI.Flow.Node{id: id, content: content}
  end # end of GenAI.Flow.Node.new/2


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


end # end of GenAI.Flow.Node
