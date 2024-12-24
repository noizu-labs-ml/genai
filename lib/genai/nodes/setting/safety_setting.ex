defmodule GenAI.Setting.SafetySetting do
  @vsn 1.0

  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    category: nil,
    threshold: nil
  ]
  defnodetype [
    category: any,
    threshold: any
  ]
end

defimpl GenAI.SettingProtocol, for: GenAI.Setting.SafetySetting do
  def stub(_), do: :ok
end