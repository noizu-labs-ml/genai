defmodule GenAI.Provider.Setting do
  @vsn 1.0
  defstruct [
    provider: nil,
    setting: nil,
    value: nil,
    vsn: @vsn
  ]
end