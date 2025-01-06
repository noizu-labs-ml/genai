defmodule GenAI.GraphTest do
    use ExUnit.Case
    
    doctest GenAI.Graph
    doctest GenAI.GraphProtocol


    describe "Mermaid Render" do
      test "Empty Graph" do
        sut = GenAI.Graph.new(id: :A)
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> A
                 state "Empty Graph" as A
               """ == mermaid
      end

      test "Single Node Graph - no head " do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node1))
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
               """ == mermaid
      end

      test "Single Node Graph" do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node1), head: true)
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> Node1
               """ == mermaid
      end

      test "Graph with Unlinked Node" do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node1), head: true)
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node2))
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> Node1
               """ == mermaid
      end


      test "Graph with Linked Node" do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node1), head: true)
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node2))
              |> GenAI.GraphProtocol.add_link(GenAI.Graph.Link.new(:Node1, :Node2))
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> Node1
               """ == mermaid
      end

      test "Graph with MultiLink" do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node1), head: true)
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node2))
              |> GenAI.GraphProtocol.add_node(GenAI.Graph.Node.new(id: :Node3))
              |> GenAI.GraphProtocol.add_link(GenAI.Graph.Link.new(:Node1, :Node2))
              |> GenAI.GraphProtocol.add_link(GenAI.Graph.Link.new(:Node1, :Node3))
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> Node1
               """ == mermaid
      end


    end
end