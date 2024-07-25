
defimpl GenAi.Graph.NodeProtocol, for: GenAI.Graph.SettingNode do
  def apply(node, state)
  def apply(node, state) do
    GenAI.Thread.StateProtocol.with_setting(state, node.setting, node.value)
  end
end
