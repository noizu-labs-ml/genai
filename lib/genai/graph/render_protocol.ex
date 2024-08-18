defprotocol GenAI.Graph.Mermaid do

  def mermaid_id(id)

  def encode(graph_element)
  def encode(graph_element, options)
  def encode(graph_element, options, state)
end

defmodule GenAI.Graph.Mermaid.Helpers do
  def mermaid_id(id) do
    cond do
      is_bitstring(id) -> String.replace(id, "-", "_")
      :else -> id
    end
  end

  def indent(string, depth \\ 1)
  def indent(string, depth) when depth in [0, nil], do: string
  def indent(string, depth) do
    padding = String.duplicate("  ", depth)
    string
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
    |> String.split("\n")
    |> Enum.map(
         fn
           "" -> ""
           line -> padding <> line
         end
       )
    |> Enum.join("\n")
  end

  def diagram_type(options)
  def diagram_type(_) do
    :state_diagram_v2
  end

end