
defmodule GenAI.Flow.Node do
  @vsn 1.0
  @moduledoc """
  Generic Flow Node
  """
  use GenAI.Flow.NodeBehaviour

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
    id = id || GenAI.UUID.new()
    %GenAI.Flow.Node{id: id, content: content}
  end # end of GenAI.Flow.Node.new/2

end # end of GenAI.Flow.Node
