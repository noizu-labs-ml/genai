defmodule GenAI.Message do
  @moduledoc """
  Struct for representing a chat message.
  """
  @vsn 1.0

  defstruct [
    role: nil,
    content: nil,
    vsn: @vsn
  ]

  @type t :: %__MODULE__{
    role: :user | :assistant | :system | any,
    content: String.t() | list(),
    vsn: float
  }

  defimpl GenAI.MessageProtocol do
    def message(message), do: message
    def multipart?(%GenAI.Message{content: content}) do
      GenAI.Message.ContentProtocol.multipart?(content)
    end
  end

end
