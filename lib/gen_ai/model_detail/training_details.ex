defmodule GenAI.ModelDetail.TrainingDetails do
  @moduledoc """
  Provides standardized structure for tracking training details such as training cut off, supplemental_training per subject cut offs, etc. censorship. instruct training, dolphin, etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct [vsn: @vsn]
end
