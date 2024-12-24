#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.Node.DefaultImplementation do
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R
  alias GenAI.Flow.Types, as: T

  # Default Implementations
  #========================================
  # id/1
  #========================================
  @spec id(T.flow_node) :: T.result(T.node_id, {:id, :blank})
  def id(%{id: nil}), do: {:error, {:id, :blank}}
  def id(%{id: id}), do: {:ok, id}

  #========================================
  # handle/1 (Default)
  #========================================
  @spec handle(T.flow_node) :: T.result(T.node_handle, {:handle, :blank})
  def handle(%{handle: nil}), do: {:error, {:handle, :blank}}
  def handle(%{handle: handle}), do: {:ok, handle}

  #========================================
  # fetch_links/2
  #========================================
  defp do_fetch_links(links, flow) do
    links = Enum.map(links,
              fn
                {inlet_outlet, link_ids} ->
                  links = Enum.map(link_ids,
                            fn link_id ->
                              with {:ok, link} <- GenAI.Flow.link(flow, link_id) do
                                {link_id, link}
                              else
                                {:error, details} ->
                                  raise GenAI.Flow.Exception,
                                        message: "Edge lookup failed",
                                        details: details
                              end
                            end
                          ) |> Map.new()
                  {inlet_outlet, links}
              end
            )
            |> Map.new()
    {:ok, links}
  end

  #========================================
  # inbound_links/2 (Default)
  #========================================
  @spec inbound_links(T.flow_node, T.flow) :: T.result(T.link_map, T.details)
  def inbound_links(node, flow) do
    do_fetch_links(node.inbound_links, flow)
  end # end of GenAI.Flow.NodeBehaviour.inbound_links/2

  #========================================
  # outbound_links/2 (Default)
  #========================================
  @spec outbound_links(T.flow_node, T.flow) :: T.result(T.link_map, T.details)
  def outbound_links(node, flow) do
    do_fetch_links(node.outbound_links, flow)
  end # end of GenAI.Flow.NodeBehaviour.outbound_links/2

  #========================================
  # with_id/1 (Default)
  #========================================
  @spec with_id(T.flow_node) :: T.result(T.flow_node, T.details)
  def with_id(node) do
    update = update_in(node, [Access.key(:id)], & &1 || UUID.uuid4())
    {:ok, update}
  end # end of GenAI.Flow.NodeBehaviour.with_id/2

  #========================================
  # register_link/2 (Default)
  #========================================
  @spec register_link(T.flow_node, T.flow_link) :: T.result(T.flow_node, T.details)
  def register_link(node, link) do
    with  {:ok, link_id} <- GenAI.Flow.LinkProtocol.id(link),
          {:ok, R.link_source(id: source, outlet: outlet)} <- GenAI.Flow.LinkProtocol.source(link),
          {:ok, R.link_target(id: target, inlet: inlet)} <- GenAI.Flow.LinkProtocol.target(link)  do
      update = cond do
        node.id == source ->
          update_in(node, [Access.key(:outbound_links), outlet], & [link_id | (&1 || [])])
        node.id == target ->
          update_in(node, [Access.key(:inbound_links), inlet], & [link_id | (&1 || [])])
      end
      {:ok, update}
    end
  end # end of GenAI.Flow.NodeBehaviour.register_link/2

#
#  #========================================
#  # apply/5 (Default)
#  #========================================
#  @doc """
#  Default implementation of apply/5
#  You generally will want to extend this for each node type.
#
#  ---
#  # Note
#  Side Effects this method may alter flow_state, the flow flow and links in said flow as well as the node itself.
#  """
#  def apply(node, inbound_link, flow, flow_state, options) do
#    outbound = GenAI.Flow.NodeProtocol.outbound_links(node, flow)
#               |> Enum.map(fn {outlet, links} -> Map.values(links) end)
#               |> List.flatten()
#
#    case outbound do
#      [] ->
#        Logger.info("Generic Node - Flow End (Please override this method in your node implementation)")
#        flow_end()
#      outbound when is_list(outbound) ->
#        # @TODO set any ephemeral outbound link state needed and update state object etc as needed. (SIDE EFFECTS)
#        # @TODO pick the appropriate next node. A chat flow with edited/alternative messages for example may have an internal state field indicating the currently selected node.
#        # @TODO clarify what state may mutate in flow and what is mutated in flow state.
#        Logger.info("Generic Node - Flow Advance (Please override this method in your node implementation)")
#        flow_advance(outbound: outbound)
#    end
#  end # end of GenAI.Flow.NodeBehaviour.apply/5
end # end of GenAI.Flow.NodeBehaviour

