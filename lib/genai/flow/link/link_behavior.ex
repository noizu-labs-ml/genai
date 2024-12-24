#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.LinkBehaviour do
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R
  alias GenAI.Flow.Types, as: T

  # Access
  @callback id(T.flow_link) ::T.result(T.link_id, T.details)
  @callback source(T.flow_link) :: T.result(R.link_source, T.details)
  @callback target(T.flow_link) :: T.result(R.link_target, T.details)

  @callback bind_source(T.flow_link, R.link_source | R.link_id) :: T.result(T.flow_link, T.details)
  @callback bind_target(T.flow_link, R.link_target | R.link_id) :: T.result(T.flow_link, T.details)

  @callback with_id(T.flow_node) :: T.result(T.flow_node, T.details)

  #========================================
  # Using Macro
  #========================================
  defmacro __using__(opts \\ nil) do
    quote do
      @behaviour GenAI.Flow.LinkBehaviour
      require GenAI.Flow.NodeBehaviour
      import GenAI.Flow.NodeBehaviour, only: [defnode: 1, defnodetype: 1]
      @link_implementation (unquote(opts[:implementation]) || GenAI.Flow.Link.DefaultImplementation)

      @impl GenAI.Flow.LinkBehaviour
      defdelegate id(node), to: @link_implementation
      @impl GenAI.Flow.LinkBehaviour
      defdelegate source(node), to: @link_implementation
      @impl GenAI.Flow.LinkBehaviour
      defdelegate target(node), to: @link_implementation

      @impl GenAI.Flow.LinkBehaviour
      defdelegate bind_source(link, value), to: @link_implementation
      @impl GenAI.Flow.LinkBehaviour
      defdelegate bind_target(link, value), to: @link_implementation

      @impl GenAI.Flow.LinkBehaviour
      defdelegate with_id(link), to: @link_implementation

      defoverridable [
        id: 1,
        source: 1,
        target: 1,
        bind_source: 2,
        bind_target: 2,
        with_id: 1
      ]
    end
  end # end of GenAI.Flow.LinkBehaviour.__using__/1

end # end of GenAI.Flow.LinkBehaviour