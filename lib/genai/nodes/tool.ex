defmodule GenAI.Tool do
  @vsn 1.0
  defstruct [
    name: nil,
    description: nil,
    parameters: %{},
    vsn: @vsn
  ]
end