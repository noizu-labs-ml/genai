defmodule GenAI.Setting.SafetySetting do
  @vsn 1.0

  use GenAI.Flow.NodeBehaviour
  # alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    category: nil,
    threshold: nil
  ]
  defnodetype [
    category: any,
    threshold: any
  ]
end

defimpl GenAI.SettingProtocol, for: GenAI.Setting.SafetySetting do
  def stub(_), do: :ok
end


defimpl GenAI.Thread.NodeProtocol, for: GenAI.Setting.SafetySetting do
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R

  @doc """
  Process node in flow (update state/effective settings, run any interstitial inference, etc.).
  """
  def process_node(node, link, container, state, options)
  def process_node(node, link, container, state, options) do
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