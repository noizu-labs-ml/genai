defmodule GenAI.Message do
  @vsn 1.0
  defstruct [
    role: nil,
    content: nil,
    vsn: @vsn
  ]

  defimpl GenAI.MessageProtocol do
    def message(message) do
      message
    end
  end

end
