defmodule GenAI.Graph.ProviderSettingNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    provider: nil,
    setting: nil,
    value: nil,
    vsn: @vsn
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_provider_setting(state, node.provider, node.setting, node.value)
    end
  end

end
