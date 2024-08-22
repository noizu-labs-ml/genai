
defmodule GenAI.ModelDetail.ModalitySupport do
  @moduledoc """
  Provides standardized structure for tracking modality support details.
    For example if a model can mimic video support by streaming images,
    plus audio transcription. Or supports native image and audio.
  """
  @vsn 1.0
  @type t ::
          %__MODULE__{
            video: any,
            image: any,
            audio: any,
            vsn: float
          }
  defstruct [
    video: nil,
    image: nil,
    audio: nil,
    vsn: @vsn
  ]
end
