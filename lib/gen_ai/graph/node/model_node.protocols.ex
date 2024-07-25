defimpl GenAi.Graph.NodeProtocol, for: [GenAI.Graph.ModelNode] do
  def apply(node, state)
  def apply(%GenAI.Graph.ModelNode{content: model_or_selector}, state) do
    cond do
      GenAI.ModelProtocol.protocol_supported?(model_or_selector) ->
        with {:ok, {registered_model, state}} <- GenAI.ModelProtocol.register(model_or_selector, state) do
          GenAI.Thread.StateProtocol.with_model(state, registered_model)
          else
          x = {:error, _} -> x
          x -> {:error, {:unexpected, x}}
        end
      :else ->
        GenAI.Thread.StateProtocol.with_model(state, model_or_selector)
    end
  end
end
