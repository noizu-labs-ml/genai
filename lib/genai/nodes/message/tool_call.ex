#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message.ToolCall do
  @vsn 1.0

  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    role: nil,
    content: nil,
    tool_calls: nil,
  ]
  defnodetype [
    role: any,
    content: any,
    tool_calls: any,
  ]

end


defimpl GenAI.MessageProtocol, for: GenAI.Message.ToolCall do
  def stub(_), do: :ok
end