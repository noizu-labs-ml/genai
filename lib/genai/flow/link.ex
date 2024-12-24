#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.Link do
  @vsn 1.0
  @doc """
  A link between two nodes in a flow.
  """
  require GenAI.Flow.Records
  alias GenAI.Flow.Types, as: T
  alias GenAI.Flow.Records, as: R

  use GenAI.Flow.LinkBehaviour

  @derive GenAI.Flow.LinkProtocol
  @type t :: %__MODULE__{
               id: T.link_id,
               type: T.link_type,
               arrow: T.link_arrow,
               source: R.link_source,
               target: R.link_target,
               label: T.link_label,
               color: T.link_color,
               settings: any,
               vsn: T.vsn,
             }

  defstruct [
    id: nil,
    type: nil,
    arrow: nil,
    source: nil,
    target: nil,
    label: nil,
    color: nil,
    settings: nil,
    vsn: @vsn,
  ]

  @doc """
  Create a new flow link
  """
  @spec new(GenAI.Flow.Records.link_source, GenAI.Flow.Records.link_target, T.opts) :: t
  def new(source, target, opts \\ nil)
  def new(R.link_source() = source, R.link_target() = target, opts) do
    id = opts[:id] || UUID.uuid4()
    %GenAI.Flow.Link{
      id: id,
      source: source,
      target: target,
      arrow: opts[:arrow] || :"-->",
      label: opts[:label],
      type: opts[:type] || :flow,
      color: opts[:color] || :default
    }
  end # end of GenAI.Flow.Link.new/2
  def new(source, target, opts) do
    source = case source do
      R.link_source() -> source
      _ -> R.link_source(id: source)
    end
    target = case target do
      R.link_target() -> target
      _ -> R.link_target(id: target)
    end
    new(source, target, opts)
  end



end # end of GenAI.Flow.Link
