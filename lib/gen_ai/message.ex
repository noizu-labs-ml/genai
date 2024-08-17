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

  @doc """
  Load image resource.
  """
  def image(resource, options \\ nil)
  def image(resource, nil) do
    GenAI.Message.Content.ImageContent.new(resource)
  end
  def image(resource, options) do
    GenAI.Message.Content.ImageContent.new(resource, options)
  end

  defimpl GenAI.MessageProtocol do
    def message(message), do: message

    def content(message)
    def content(%{content: content}) when is_bitstring(content) do
      content
    end
    def content(%{content: content}) when is_list(content) do
      Enum.map(content, & GenAI.Message.ContentProtocol.content(&1))
    end
  end

end
