defmodule GenAI.GraphTest do
    use ExUnit.Case
    
    doctest GenAI.Graph
    


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
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node1, name: "N1"))
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 state "N1" as Node1
               """ == mermaid
      end

      test "Single Node Graph" do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node1, name: "N1"), head: true)
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> Node1
                 state "N1" as Node1
               """ == mermaid
      end

      test "Graph with Unlinked Node" do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node1, name: "N1"), head: true)
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node2, name: "N2"))
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> Node1
                 state "N1" as Node1

                 state "N2" as Node2
               """ == mermaid
      end


      test "Graph with Linked Node" do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node1, name: "N1"), head: true)
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node2, name: "N2"))
              |> GenAI.Graph.add_link(GenAI.Graph.Link.new(:Node1, :Node2))
        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> Node1
                 state "N1" as Node1
                 Node1 --> Node2

                 state "N2" as Node2
               """ == mermaid
      end

      test "Graph with MultiLink" do
        sut = GenAI.Graph.new(id: :A)
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node1, name: "N1"), head: true)
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node2, name: "N2"))
              |> GenAI.Graph.add_node(GenAI.Graph.Node.new(id: :Node3, name: "N3"))
              |> GenAI.Graph.add_link(GenAI.Graph.Link.new(:Node1, :Node2))
              |> GenAI.Graph.add_link(GenAI.Graph.Link.new(:Node1, :Node3))
              |> GenAI.Graph.add_link(GenAI.Graph.Link.new(:Node2, :Node3))

        {:ok, mermaid} = GenAI.Graph.Mermaid.encode(sut)
        assert """
               stateDiagram-v2
                 [*] --> Node1
                 state "N1" as Node1
                 Node1 --> Node3
                 Node1 --> Node2

                 state "N2" as Node2
                 Node2 --> Node3

                 state "N3" as Node3
               """ == mermaid
      end


    end
end