defprotocol GenAI.Provider.LocalLLama.MessageProtocol do
  @moduledoc """
  This protocol defines how to transform GenAI message structs into a format compatible with the LocalLLama nif.
  """

  @doc """
  Transforms a GenAI message struct into a LocalLLama message format.
  """
  def message(message)
end

defimpl GenAI.Provider.LocalLLama.MessageProtocol, for: GenAI.Message do
  def message(message) do
    %{role: message.role, content: message.content}
  end
end

defimpl GenAI.Provider.LocalLLama.MessageProtocol, for: GenAI.Message.ToolCall do
  def message(_message) do
    throw "NYI"
  end
end


defimpl GenAI.Provider.LocalLLama.MessageProtocol, for: GenAI.Message.ToolResponse do
  def message(_message) do
    throw "NYI"
  end
end
