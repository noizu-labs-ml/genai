defmodule GenAI.Graph.ProviderSettingNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    provider: nil,
    setting: nil,
    value: nil,
    vsn: @vsn
  ]
end
