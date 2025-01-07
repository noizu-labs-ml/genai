#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message do
    @vsn 1.0
    @moduledoc false
    
    use GenAI.Graph.NodeBehaviour
    @derive GenAI.Graph.NodeProtocol
    defnodetype [
        role: term,
        content: term,
    ]
    
    defnodestruct [
        role: nil,
        content: nil,
    ]
    
    
    def new(role, message) do
        id = UUID.uuid4()
        %__MODULE__{
            id: id,
            role: role,
            content: message
        }
    end
    
    def user(message) do
        new(:user, message)
    end
    
    def system(message) do
        new(:system, message)
    end
    
    def assistant(message) do
        new(:assistant, message)
    end
end


defimpl GenAI.MessageProtocol, for: GenAI.Message do
    def supported?(_), do: true
end

defimpl GenAI.Session.NodeProtocol, for: GenAI.Message do
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
    IO.inspect(graph_node.content, label: "MSG")
    updated_state = state
    # TODO - outbound links protocol method needed.
    with {:ok, links} <-
           GenAI.Graph.NodeProtocol.outbound_links(graph_node, container, expand: true) |> IO.inspect(label: "outbound") do
      # Single node support only
      links = links
              |> Enum.map(fn {socket, links} -> links end)
              |> List.flatten()
      |> IO.inspect(label: "OUTBOUND")
      case links do
        [] -> Node.process_end(exit_on: {graph_node, :no_links}, update: Node.process_update(state: updated_state))
        [link] ->
          Node.process_next(link: link, update: Node.process_update(state: updated_state))
          |> IO.inspect(label: "RETURN")
      end
    end
  end
end