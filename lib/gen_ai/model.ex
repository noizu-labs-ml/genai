defmodule GenAI.Model do
  @vsn 1.0
  defstruct [
    provider: nil,
    model: nil,
    details: nil,
    vsn: @vsn
  ]

  defimpl GenAI.ModelProtocol do
    def protocol_supported?(_), do: true
    def provider(model), do: {:ok, model.provider}
    def model(model), do: {:ok, model.model}
  end

end
