defprotocol GenAI.Provider.LocalLLama.ToolProtocol do
  @moduledoc """
  This protocol defines how to transform GenAI tool function structs into a format compatible with the LocalLLama nif.
  """

  @doc """
  Transforms a GenAI tool function struct into a Groq tool format.
  """
  def tool(subject)
end

defimpl GenAI.Provider.LocalLLama.ToolProtocol, for: GenAI.Tool.Function do
  def tool(_subject) do
    throw "NYI"
  end
end
