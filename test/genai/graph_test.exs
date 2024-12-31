defmodule GenAI.GraphTest do
  use ExUnit.Case

  doctest GenAI.Graph
  doctest GenAI.GraphProtocol
  require GenAI.Graph.Asserts
  import GenAI.Graph.Asserts
  @moduletag :wip

  describe "Custom Asserts" do

    test "assert is_graph" do
      sut = GenAI.Graph.new()
      assert is_graph(sut)
    end

    test "refute is_graph" do
      sut = %{}
      refute is_graph(sut)
    end

    test "assert is_link" do
      sut = GenAI.Graph.Link.new(:a,:b)
      assert is_link(sut)
    end

    test "refute is_link" do
      sut = %{}
      refute is_link(sut)
    end


    test "assert is_node" do
      sut = GenAI.Graph.Node.new()
      assert is_node(sut)
    end

    test "refute is_node" do
      sut = %{}
      refute is_node(sut)
    end

    test "assert nodes" do
      sut = GenAI.Graph.new()



    end


  end


  describe "Graph Internal State" do



  end

end