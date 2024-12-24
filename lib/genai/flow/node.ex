#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.Node do
  @vsn 1.0
  @moduledoc """
  Generic Flow Node
  """
  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    content: nil,
    state: nil,
  ]
  defnodetype [
    content: any,
    state: any,
  ]

  #========================================
  # new/1
  #========================================
  @doc """
  Create a new flow node
  """
  @spec new(id :: T.node_id, content :: any, T.options) :: any
  def new(id, content \\ nil, options \\ nil)
  def new(id, content, _options) do
    id = id || UUID.uuid4()
    %GenAI.Flow.Node{id: id, content: content}
  end # end of GenAI.Flow.Node.new/2

end # end of GenAI.Flow.Node
