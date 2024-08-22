defmodule GenAI.ModelDetail.BenchMarks do
  @moduledoc """
  Last reported model evaluation benchmark scores.
  """
  @vsn 1.0
  @type t :: %__MODULE__{
               benchmarks: Map.t,
               vsn: float
             }
  defstruct [
    benchmarks: %{},
    vsn: @vsn
  ]
end
