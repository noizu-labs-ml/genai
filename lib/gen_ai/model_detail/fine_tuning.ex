defmodule GenAI.ModelDetail.FineTuning do
  @moduledoc """
  Tracks fine tuning details for the model, if any.
  - Type of fine tuning
  - Fine Tuning Date
  - Fine Tuning Notes
  """

  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct [vsn: @vsn]
end
