defmodule GenAI.Setting.ProviderSetting do
  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    provider: nil,
    setting: nil,
    value: nil
  ]
  defnodetype [
    provider: any,
    setting: any,
    value: any
  ]
end

defimpl GenAI.SettingProtocol, for: GenAI.Setting.ProviderSetting do
  def stub(_), do: :ok
end