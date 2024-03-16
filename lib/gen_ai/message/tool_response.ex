defmodule GenAI.Message.ToolResponse do
  @vsn 1.0
  defstruct [
    response: nil,
    tool_call_id: nil,
    vsn: @vsn
  ]

  defimpl GenAI.MessageProtocol do
    def message(message) do
      message
    end
  end

end
