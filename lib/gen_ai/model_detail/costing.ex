defmodule GenAI.ModelDetail.Costing do
  @moduledoc """
  Provides standardized structure for tracking costing details.
  - cost per million input tokens
  - cost per million output tokens
  - cost per hour
  - cost per request
  - media costs
  """
  @vsn 1.0
  @type t ::
          %__MODULE__{
            million_input_tokens: float | nil,
            million_output_tokens: float | nil,
            per_request: float | nil,
            per_instance_hour: float | nil,
            media: Map.t | nil, # tile_size, base_tokens, tokens_per_tile
            vsn: float
          }
  defstruct [
    million_input_tokens: nil,
    million_output_tokens: nil,
    per_request: nil,
    per_instance_hour: nil,
    media: nil,
    vsn: @vsn
  ]
end
