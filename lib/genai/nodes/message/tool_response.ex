#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message.ToolResponse do
  @vsn 1.0

  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    name: nil,
    response: nil,
    tool_call_id: nil,
  ]
  defnodetype [
    name: any,
    response: any,
    tool_call_id: any,
  ]
end


defimpl GenAI.MessageProtocol, for: GenAI.Message.ToolResponse do
  def stub(_), do: :ok
end