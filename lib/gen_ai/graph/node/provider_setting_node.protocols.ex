  defimpl GenAi.Graph.NodeProtocol, for: GenAI.Graph.ProviderSettingNode do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_provider_setting(state, node.provider, node.setting, node.value)
    end
  end
