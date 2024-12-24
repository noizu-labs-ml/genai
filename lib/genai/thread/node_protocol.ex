defprotocol GenAI.Thread.NodeProtocol do

  @doc """
  Process node and proceed to next step.
  """
  def process_node(node, link, container, state, options)

end

defmodule GenAI.Thread.NodeProtocol.Runner do
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R

  def update_state(R.flow_update(node: update_node, container: update_container, state: update_state), node, container, state, options) do
    state = cond do
        update_state -> GenAI.Flow.State.update(state, update_state)
        :else -> state
    end
    container = cond do
        update_container ->
          container
          #GenAI.Flow.update(container, update_container)
        :else -> container
    end
    node = cond do
        update_node ->
          node
          #GenAI.Flow.Node.update(node, update_node)
        :else -> node
    end
    {:ok, {node, container, state}}
  end

  def process_nodes(node, link, container, state, options) do
    case GenAI.Thread.NodeProtocol.process_node(node, link, container, state, options) do
      {:ok, R.flow_advance(links: links, update: update)} ->
        # @todo we need to append tracking information as we walk into structure
        # @todo async_stream
        {:ok, {node, container, state}} = update_state(update, node, container, state, options)
        temp = Enum.map(links,
          fn link ->
            with {:ok, R.link_target(id: node_id)} <- GenAI.Flow.Link.target(link),
                 {:ok, next_node} <- GenAI.Flow.node(container, node_id) do

              # handle error
              {:ok, response} = GenAI.Thread.NodeProtocol.Runner.process_nodes(next_node, link, container, state, options)
              response
            end
          end
        ) |> IO.inspect(label: "Advance NYI")
        |> List.flatten()
        |> List.last() # todo merge end_flow nodes.
        {:ok, temp}
      x = {:ok, R.flow_yield(for: for, update: update)} ->
        raise GenAI.Flow.Exception, "Yield Not Yet Implemented"
      x = {:ok, R.flow_end(exit_point: exit_points, update: update)} ->
        x
      x = {:error, R.flow_error(exit_point: exit_points, details: details, update: update)} ->
        x
    end
  end


end