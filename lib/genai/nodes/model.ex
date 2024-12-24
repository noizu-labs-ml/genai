defmodule GenAI.Model do
  @vsn 1.0

  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    provider: nil,
    model: nil,
    details: nil,
  ]
  defnodetype [
    provider: any,
    model: any,
    details: any,
  ]
end


defimpl GenAI.ModelProtocol, for: GenAI.Model do
  def stub(_), do: :ok
end