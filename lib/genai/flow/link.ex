defmodule GenAI.Flow.Link do
  @vsn 1.0
  @doc """
  A link between two nodes in a flow.
  """

  @type id :: term
  @type t :: %GenAI.Flow.Link{
               id: id,
               source: id,
               source_outlet: term,
               target: id,
               target_inlet: term,
               arrow: term,
               label: String.t,
               type: atom | tuple,
               color: atom,
               vsn: float,
             }

  defstruct [
    id: nil,
    source: nil,
    source_outlet: :default,
    target: nil,
    target_inlet: :default,
    arrow: :"->",
    label: nil,
    type: :flow,
    color: nil,
    vsn: @vsn,
  ]

  @doc """
  Create a new flow link
  """
  @spec new(source :: id, target :: id, options :: nil | Map.t) :: t
  def new(source, target, options \\ nil) do
    id = options[:id] || GenAI.UUID.new()
    %GenAI.Flow.Link{
      id: id,
      source: source,
      source_outlet: options[:source_outlet] || :default,
      target: target,
      target_inlet: options[:target_inlet] || :default,
      arrow: options[:arrow] || :"->",
      label: options[:label],
      type: options[:type] || :flow,
      color: options[:color]
    }
  end # end of GenAI.Flow.Link.new/2

  def new_note_link(source, target, options \\ nil) do
    id = options[:id] || GenAI.UUID.new()
    %GenAI.Flow.Link{
      id: id,
      source: source,
      target: target,
      arrow: options[:arrow] || :"-",
      label: options[:label],
      type: options[:type] || :note,
      color: options[:color]
    }
  end # end of GenAI.Flow.Link.new/2

end # end of GenAI.Flow.Link
