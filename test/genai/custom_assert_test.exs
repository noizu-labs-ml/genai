defmodule GenAI.CustomAssertTest do
  use ExUnit.Case
  use GenAI.Graph.Asserts

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
            |> GenAI.Graph.add_node(GenAI.Graph.Node.new(handle: :a, name: "bob"))
            |> GenAI.Graph.add_node(GenAI.Graph.Node.new(handle: :b, name: "bob"))
            |> GenAI.Graph.add_node(GenAI.Graph.Node.new(handle: :c, name: "barb"))
      assert is_graph(sut)
      assert graph_size(sut) == 3
      assert graph_node(sut, handle: :a)
      assert graph_node(sut, handle: :b)
      refute graph_node(sut, handle: :not_valid)
      #assert_has
      

      # The interface for custom asserts (which can then themselves be put into their own custom asserts with input clauses)
      # might look like the below.
      # behind the scenes the pipe operators construct a query object containing partials/ast tags
      # that are compiled as the last step (allowing a chain to be reused/modified)
      # to generated code performing each of the assertions/filters


#      assert_graph sut
#                   |> section("Name A")
#                   |> is_graph("Expected a graph")
#                   |> count( nodes(of_type(UserNodeTypeProtocol)) < 5 && nodes(of_type(UserNodeTypeProtocol)) > 2, "Unexpected Number of Nodes")
#                   |> count( links(of_type(UserLinkTypeProtocol))  != 3)
#                   |> has(description() =~ "Snippet")
#                   |> has(label() in [:a,:b,:c])
#                   |> section("Name B")
#                   |> contains(nodes() in [%{foo: 1},%{bar: 2}, %{baz: 3}])
#                   |> only(contains(links() in [^a, ^b, ^c]), "Unexpected Links Found")
#                   |> does_not(have(description() = "Not Allowed"))
#                   |> does_not(have(link() in [^invalid]))
#                   |> does_not(contain(links() in [^invalid]))
#                   |> has(link_from(head(), to: node_a = graph_node(has(label() == :a)), like: link( socket(source()) == :first_link)), "Expected had to point to a")
#                   |> has(link_from(node_a, to: node_b = graph_node(has(label() == :b), over: :socket_name), "Expected a to point to b")
#                   |> only(has(link_from(node_b, to: graph_node(has(label() == :c))), "Expected b to only link to c"))
#                   |> has(partial_graph = path(  head() ~> to(graph_node(label() == :c), over: :socket_name)  ~> node_c ))
#                   |> and_group(_a, _b, or_group(b,c))
#                   |> if_group(sentinel, then: _a, else: b)















    end


  end


end