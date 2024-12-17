
defmodule GenAI.Message.ToolResponse do
  @vsn 1.0
  defstruct [
    name: nil,
    response: nil,
    tool_call_id: nil,
    vsn: @vsn
  ]

end
