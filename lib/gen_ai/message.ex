defmodule GenAI.Message do
  @vsn 1.0
  defstruct [
    role: nil,
    content: nil,
    handle: nil,
    vsn: @vsn
  ]

  defimpl GenAI.MessageProtocol do
    def message(message) do
      message
    end
  end

end


defmodule GenAI.DynamicMessage do
  @vsn 1.0
  defstruct [
    role: nil,
    handle: nil,
    conventions: nil,
    prompt: nil, # should be prompt
    vsn: @vsn
  ]

  defimpl GenAI.MessageProtocol do
    def message(message) do
      message
    end
  end

end
