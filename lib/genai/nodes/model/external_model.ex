defmodule GenAI.Model.ExternalModel do
  @vsn 1.0
  @enforce_keys [:handle, :manager]
  defstruct [
    handle: nil,
    provider: nil,

    manager: nil,
    external: nil,
    configuration: nil,

    details: nil,
    vsn: @vsn
  ]
end