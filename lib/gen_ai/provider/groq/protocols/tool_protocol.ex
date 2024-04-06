defprotocol GenAI.Provider.Groq.ToolProtocol do
  @moduledoc """
  This protocol defines how to transform GenAI tool function structs into a format compatible with the Groq tool API.
  """

  @doc """
  Transforms a GenAI tool function struct into a Groq tool format.
  """
  def tool(subject)
end

defimpl GenAI.Provider.Groq.ToolProtocol, for: GenAI.Tool.Function do
  def tool(subject) do
    %{type: :function, function: subject}
  end
end
