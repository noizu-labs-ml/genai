#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.NodeBehaviour do
  #require GenAI.Flow.Records
  #alias GenAI.Flow.Records, as: R
  alias GenAI.Flow.Types, as: T

  # Access
  @callback id(T.flow_node) :: T.result(T.node_id, T.details)
  @callback handle(T.flow_node) :: T.result(T.node_handle, T.details)
  #@callback content(T.flow_node) :: T.result(T.content, T.details)
  #@callback state(T.flow_node) :: T.result(T.node_state, T.details)
  @callback inbound_links(T.flow_node, T.flow) :: T.result(T.link_map, T.details)
  @callback outbound_links(T.flow_node, T.flow) :: T.result(T.link_map, T.details)
  # Mutate
  @callback with_id(T.flow_node) :: T.result(T.flow_node, T.details)
  @callback register_link(T.flow_node, T.link) :: T.result(T.flow_node, T.details)
  # @callback apply(T.flow_node, inbound :: T.edge, T.flow, T.flow_state, T.options) :: GenAI.Flow.apply_flow_responses

  #========================================
  # Using Macro
  #========================================
  defmacro __using__(opts \\ nil) do
    quote do
      @behaviour GenAI.Flow.NodeBehaviour
      require GenAI.Flow.NodeBehaviour
      import GenAI.Flow.NodeBehaviour, only: [defnode: 1, defnodetype: 1]
      @node_implementation (unquote(opts[:implementation]) || GenAI.Flow.Node.DefaultImplementation)

      @impl GenAI.Flow.NodeBehaviour
      defdelegate id(node), to: @node_implementation
      @impl GenAI.Flow.NodeBehaviour
      defdelegate handle(node), to: @node_implementation
      @impl GenAI.Flow.NodeBehaviour
      defdelegate inbound_links(node, flow), to: @node_implementation
      @impl GenAI.Flow.NodeBehaviour
      defdelegate outbound_links(node, flow), to: @node_implementation

      @impl GenAI.Flow.NodeBehaviour
      defdelegate with_id(node), to: @node_implementation
      @impl GenAI.Flow.NodeBehaviour
      defdelegate register_link(node, link), to: @node_implementation

#      @impl GenAI.Flow.NodeBehaviour
#      defdelegate apply(node, inbound_edge, flow, flow_state, options), to: GenAI.Flow.NodeBehaviour
      defoverridable [
        id: 1,
        handle: 1,
        #content: 1,
        #state: 1,
        inbound_links: 2,
        outbound_links: 2,
        register_link: 2,
        #apply: 5
      ]
    end
  end # end of GenAI.Flow.NodeBehaviour.__using__/1


  defmacro defnodetype(types) do
    types = Macro.expand_once(types, __CALLER__)
    members = quote do
      [
        {:id, T.node_id},
        {:handle, T.node_handle},
        unquote_splicing(types),
        {:inbound_links, T.link_map},
        {:outbound_links, T.link_map},
        {:meta, nil | map() | keyword()},
        {:vsn, float}
      ]
    end


    quote do
      @type t :: %__MODULE__{
                   unquote_splicing(members)
                 }
    end
  end

  defmacro defnode(values) do



    quote do
      @vsn Module.get_attribute(__MODULE__, :vsn, 1.0)
      defstruct [
                  id: nil,
                  handle: nil
                ] ++
                (unquote(values) || []) ++
                [
                  outbound_links: %{}, # edge ids grouped by outlet
                  inbound_links: %{}, # edge ids grouped by outlet
                  vsn: @vsn,
                  meta: nil,
                ]
    end # end of quote
  end # end of GenAI.Flow.NodeBehaviour.def_node/1
end # end of GenAI.Flow.NodeBehaviour