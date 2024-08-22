defmodule GenAI.ExternalModel do
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

  defimpl GenAI.ModelProtocol do
    def protocol_supported?(_), do: true
    def identifier(model), do: {:ok, model.handle}
    def provider(model), do: {:ok, model.provider}
    def model(model) do
      IO.puts "TODO: fetch live model from manager"
      {:ok, model}
    end
    def register(model, state), do: {:ok, {model, state}}
  end
end
