defmodule GenAI.Graph.Node do
  @vsn 1.0
  @moduledoc """
  Represent a node on graph (generic type).
  """
  
  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  defnodetype [
      value: term
  ]
  
  defnodestruct [
      value: nil,
  ]

  @doc """
  Create a new node.
  """
  def new(options \\ nil) do
    %__MODULE__{
      id: options[:id] || UUID.uuid4(),
      handle: options[:handle] || nil,
      name: options[:name] || nil,
      description: options[:description] || nil,
      inbound_links: %{},
      outbound_links: %{},
    }
  end

end



defimpl GenAI.Graph.Mermaid, for: GenAI.Graph.Node do
  require GenAI.Graph.Link.Records
  alias GenAI.Graph.Link.Records, as: R


  
  def mermaid_id(subject) do
      GenAI.Graph.Mermaid.Helpers.mermaid_id(subject.id)
  end

  def encode(graph_element), do: encode(graph_element, [])
  def encode(graph_element, options), do: encode(graph_element, options, %{})
  def encode(graph_element, options, state) do
    case GenAI.Graph.Mermaid.Helpers.diagram_type(options) do
      :state_diagram_v2 -> state_diagram_v2(graph_element, options, state)
      x -> {:error, {:unsupported_diagram, x}}
    end
  end
  
  
  
  def state_diagram_v2(graph_node, _options, state) do
      identifier = GenAI.Graph.Mermaid.Helpers.mermaid_id(graph_node.id)
      container = List.first(state[:container])
      n = cond do
          graph_node.name ->
              """
              state "#{graph_node.name}" as #{identifier}
              """
          
          graph_node.handle ->
              """
              state "#{graph_node.handle}" as #{identifier}
              """
          
          :else ->
              """
              state "A Node" as #{identifier}
              """
      end
      
      transitions = Enum.map(graph_node.outbound_links,
                        fn {_, links} ->
                          Enum.map(links,
                              fn link_id ->
                                # TODO - Node protocol needs to return a get_link method that accepts node, container
                                {:ok, link} = GenAI.GraphProtocol.link(container, link_id)
                                {:ok, R.connector(node: n)} = GenAI.Graph.LinkProtocol.target_connector(link)
                                "#{identifier} --> #{GenAI.Graph.Mermaid.Helpers.mermaid_id(n)}"
                              end)
                        end)
                    |> List.flatten()
                    |> Enum.join("\n")
      
      if transitions != "" do
          graph = n <> transitions <> "\n"
          {:ok, graph}
      else
          graph = n <> transitions
          {:ok, graph}
      end
  end
end