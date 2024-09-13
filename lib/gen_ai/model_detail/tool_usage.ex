defmodule GenAI.ModelDetail.ToolUsage do
  @moduledoc """
  Provides details on tool usage support: native (api level), prompt injection, no support, etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct [
    vsn: @vsn,
    support: :native
  ]
end
