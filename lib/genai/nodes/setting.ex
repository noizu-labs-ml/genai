defmodule GenAI.Setting do
  @vsn 1.0

  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    setting: nil,
    value: nil
  ]
  defnodetype [
    setting: any,
    value: any
  ]
end

defimpl GenAI.SettingProtocol, for: GenAI.Setting do
  def stub(_), do: :ok
end