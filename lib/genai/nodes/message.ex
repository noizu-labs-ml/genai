#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message do
  @vsn 1.0
  @moduledoc """
  Struct for representing a chat message.
  """

  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    role: nil,
    content: nil,
  ]
  defnodetype [
    role: any,
    content: any,
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
  def stub(_), do: :ok
end



defimpl GenAI.Thread.NodeProtocol, for: GenAI.Message do
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R

  @doc """
  Process node in flow (update state/effective settings, run any interstitial inference, etc.).
  """
  def process_node(node, link, container, state, options)
  def process_node(node, link, container, state, options) do
    IO.inspect(%{role: node.role, content: node.content}, label: "Process Node")
    with {:ok, links} <- GenAI.Flow.NodeProtocol.outbound_links(node, container) do
      links = Enum.map(links, fn {_,l} -> Enum.map(l, fn {_,link} -> link end)   |> List.flatten() end) |> List.flatten()
      unless links == [] do
        {:ok, R.flow_advance(links: links, update: R.flow_update())}
      else
        {:ok, R.flow_end(exit_point: [node.id], update: R.flow_update())}
      end
    end
  end
end