defmodule GenAI.Message.Content.TextContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct [
    text: nil,
    vsn: @vsn
  ]

  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end

end
