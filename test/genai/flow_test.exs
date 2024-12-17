defmodule GenAI.FlowTest do
  use ExUnit.Case
  doctest GenAI.Flow
  alias GenAI.Flow
  alias GenAI.Flow.Node


  def assert_flow(flow, constraints) do
    Enum.map(constraints,
      fn
        {:is_flow, true} -> assert_is_flow(flow)
        {:is_flow, type} -> assert_is_flow(flow, type)
        {:vertices, constraints} -> assert_flow_vertices(flow, constraints)
        {:edges, constraints} -> assert_flow_edges(flow, constraints)
      end
    )
  end

  def assert_is_flow(flow, type \\ GenAI.Flow) do
    assert flow.__struct__ == type
  end

  def assert_flow_vertices(flow, constraints) do
    Enum.map(constraints,
      fn
        {:count, count} -> assert_flow_vertices_count(flow, count)
        {:match, match} -> assert_flow_vertices_match(flow, match)
      end
    )
  end

  def assert_flow_vertices_count(flow, count) do
    assert Enum.count(flow.vertices) == count
  end

  def assert_flow_vertices_match(flow, matches) do
    Enum.with_index(flow.vertices)
    |> Enum.map(
         fn  {{_,node}, index} ->
           assert_flow_vertex(node, get_in(matches, [Access.at(index)]))
         end
       )
  end

  def assert_flow_vertex(node, constraints) do
    Enum.map(constraints,
      fn
        {:id, value} ->
          assert_flow_vertex_id(node, value)
        {:outbound_edges, constraints} -> assert_flow_vertex_outbound_edges(node, constraints)
        {:inbound_edges, constraints} -> assert_flow_vertex_inbound_edges(node, constraints)
      end
    )
  end

  def assert_flow_vertex_id(node, value) do
    {:ok, id} = GenAI.Flow.NodeProtocol.id(node)
    assert id == value
  end


  def assert_flow_vertex_inbound_edges(node, constraints) do
    Enum.map(constraints,
      fn
        {:count, {outlet, count}} ->
          assert Enum.count(node.inbound_edges[outlet]) == count
        {:value, value} ->
          assert node.inbound_edges == value
      end
    )
  end

  def assert_flow_vertex_outbound_edges(node, constraints) do
    Enum.map(constraints,
      fn
        {:count, {outlet, count}} ->
          assert Enum.count(node.outbound_edges[outlet]) == count
        {:value, value} ->
          assert node.outbound_edges == value
      end
    )
  end



  def assert_flow_edges(flow, constraints) do
    Enum.map(constraints,
      fn
        {:count, count} -> assert_flow_edges_count(flow, count)
        {:match, match} -> assert_flow_edges_match(flow, match)
      end
    )
  end

  def assert_flow_edges_count(flow, count) do
    assert Enum.count(flow.edges) == count
  end

  def assert_flow_edges_match(flow, matches) do
    Enum.with_index(flow.edges)
    |> Enum.map(
         fn  {{_,node}, index} ->
           assert_flow_edge(node, get_in(matches, [Access.at(index)]))
         end
       )
  end

  def assert_flow_edge(edge, constraints) do
    Enum.map(constraints,
      fn
        {:id, value} ->
          assert_flow_edge_id(edge, value)
        {:target, value} ->
          assert_flow_edge_target(edge, value)
        {:source, value} ->
          assert_flow_edge_source(edge, value)
      end
    )
  end

  def assert_flow_edge_source(edge, value) do
    assert edge.source == value
  end

  def assert_flow_edge_target(edge, value) do
    assert edge.target == value
  end

  def assert_flow_edge_id(edge, value) do
    assert edge.id == value
  end



  describe "define flow" do

    test "add multiple nodes to flow" do
      flow = Flow.new()
             |> Flow.add_vertex(Node.new(:node_1))
             |> Flow.add_vertex(Node.new(:node_2))

      assert_flow(flow,
        %{
          is_flow: true,
          vertices: [
            count: 2,
            match: [
              %{id: :node_1},
              %{id: :node_2}
            ]
          ]
        }
      )
    end


    test "add edges" do
      sut = GenAI.Flow.new(id: :test_flow)
            |> GenAI.Flow.add_vertex(GenAI.Flow.Node.new(:test_node_a))
            |> GenAI.Flow.add_vertex(GenAI.Flow.Node.new(:test_node_b))
            |> GenAI.Flow.add_vertex(GenAI.Flow.Node.new(:test_node_c))
            |> GenAI.Flow.add_vertex(GenAI.Flow.Node.new(:test_node_d))
            |> GenAI.Flow.add_edge(GenAI.Flow.Link.new(:test_node_a, :test_node_b, id: :test_edge_ab))
            |> GenAI.Flow.add_edge(GenAI.Flow.Link.new(:test_node_a, :test_node_c, id: :test_edge_ac))
            |> GenAI.Flow.add_edge(GenAI.Flow.Link.new(:test_node_c, :test_node_d, id: :test_edge_cd))

      assert_flow(sut,
        %{
          is_flow: true,
          vertices: [
            count: 4,
            match: [
              %{
                id: :test_node_a,
                outbound_edges: %{
                  count: {:default, 2},
                  value: %{default: [:test_edge_ac, :test_edge_ab]}
                }
              },
              %{
                id: :test_node_b,
                inbound_edges: %{
                  count: {:default, 1},
                  value: %{default: [:test_edge_ab]}
                }
              },
              %{
                id: :test_node_c,
                inbound_edges: %{
                  count: {:default, 1},
                  value: %{default: [:test_edge_ac]}
                },
                outbound_edges: %{
                  count: {:default, 1},
                  value: %{default: [:test_edge_cd]}
                }
              },
              %{
                id: :test_node_d,
                inbound_edges: %{
                  count: {:default, 1},
                  value: %{default: [:test_edge_cd]}
                }
              }
            ]
          ],
          edges: [
            count: 3,
            match: [
              %{id: :test_edge_ab, source: :test_node_a, target: :test_node_b},
              %{id: :test_edge_ac, source: :test_node_a, target: :test_node_c},
              %{id: :test_edge_cd, source: :test_node_c, target: :test_node_d}
            ]
          ]
        }
      )
    end
  end
end