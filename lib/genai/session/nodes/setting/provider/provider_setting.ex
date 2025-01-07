#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Setting.ProviderSetting do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    defnodetype [
        provider: any,
        setting: any,
        value: any
    ]
    
    defnodestruct [
        provider: nil,
        setting: nil,
        value: nil
    ]
end

defimpl GenAI.SettingProtocol, for: GenAI.Setting.ProviderSetting do
    def supported?(_), do: true
end

defimpl GenAI.Session.NodeProtocol, for: GenAI.Setting.ProviderSetting do
  require GenAI.Session.Node.Records
  alias GenAI.Session.Node.Records, as: Node
  require GenAI.Graph.Link.Records
  alias GenAI.Graph.Link.Records, as: Link


  def process_node(graph_node, graph_link, container, state, runtime, context, options)
  def process_node(graph_node, graph_link, container, state, runtime, context, options) do
    # Update state,
    # Emit Telemetry/Monitors
    # Populate effective state in state under id.
    IO.inspect("APPLY - #{__MODULE__}")
    updated_state = state
    # TODO - outbound links protocol method needed.
    with {:ok, links} <-
           GenAI.Graph.NodeProtocol.outbound_links(graph_node, container, expand: true) do
      # Single node support only
      links = links
              |> Enum.map(fn {socket, links} -> links end)
              |> List.flatten()
      case links do
        [] ->
          Node.process_end(exit_on: {graph_node, :no_links}, update: Node.process_update(state: updated_state))
        [link] ->
          Node.process_next(link: link, update: Node.process_update(state: updated_state))
      end
    end
  end
end