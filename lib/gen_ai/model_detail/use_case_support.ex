defmodule GenAI.ModelDetail.UseCaseSupport do
  @moduledoc """
  Provides standardized structure for tracking use case support details.
  Where use case is the ability of the model to perform a task like feature extraction, generating synthetic memories, etc.
  Tracks both per model fixed scores plus dynamic adjustments based on system/user feedback.
  """
  @vsn 1.0
  @type t :: %__MODULE__{
               use_cases: Map.t,
               vsn: float
             }
  defstruct [
    use_cases: %{},
    vsn: @vsn
  ]
end
