defmodule GenAI.Graph.SettingNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    setting: nil,
    value: nil,
    vsn: @vsn
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_setting(state, node.setting, node.value)
    end
  end
end
