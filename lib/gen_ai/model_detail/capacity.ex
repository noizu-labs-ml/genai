defmodule GenAI.ModelDetail.Capacity do
  @moduledoc """
  Provides standardized structure for tracking capacity details.

  - requests per minute
  - tokens per minute
  - tokens per day
  - inference_speed
  - vram
  """

  @vsn 1.0
  @type t ::
          %__MODULE__{
            tokens_per_minute: integer | nil,
            requests_per_minute: integer | nil,
            tokens_per_day: integer | nil,
            inference_speed: float | nil,
            vram: integer | nil,
            vsn: float
          }
  defstruct [
    tokens_per_minute: nil,
    requests_per_minute: nil,
    tokens_per_day: nil,
    inference_speed: nil,
    vram: nil,
    vsn: @vsn
  ]
end
