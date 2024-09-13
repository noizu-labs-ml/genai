defmodule GenAI.ModelDetail.HyperParamSupport do
  @moduledoc """
  Provides standardized structure for tracking hyper parameter support such as allowed values, ranges, mapping etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct [
    vsn: @vsn,
    disabled: MapSet.new([]),
    supported: %{}, # value -> range or list of enums
  ]
end
