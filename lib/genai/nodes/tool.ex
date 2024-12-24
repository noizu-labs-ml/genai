defmodule GenAI.Tool do
  @vsn 1.0


  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    name: nil,
    description: nil,
    parameters: %{},
  ]
  defnodetype [
    name: any,
    description: any,
    parameters: any,
  ]
end

defimpl GenAI.ToolProtocol, for: GenAI.Tool do
  def stub(_), do: :ok
end