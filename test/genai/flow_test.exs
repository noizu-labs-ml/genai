defmodule GenAI.FlowTest do
  use ExUnit.Case
  alias GenAI.Flow
  alias GenAI.Flow.Node
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R
  require GenAI.Flow.Types
  alias GenAI.Flow.Types, as: T
  doctest GenAI.Flow


  def assert_flow(flow, constraints) do
    Enum.map(constraints,
      fn
        {:is_flow, true} -> assert_is_flow(flow)
        {:is_flow, type} -> assert_is_flow(flow, type)
        {:nodes, constraints} -> assert_flow_nodes(flow, constraints)
        {:links, constraints} -> assert_flow_links(flow, constraints)
      end
    )
  end

  def assert_is_flow(flow, type \\ GenAI.Flow) do
    assert flow.__struct__ == type
  end

  def assert_flow_nodes(flow, constraints) do
    Enum.map(constraints,
      fn
        {:count, count} -> assert_flow_nodes_count(flow, count)
        {:match, match} -> assert_flow_nodes_match(flow, match)
      end
    )
  end

  def assert_flow_nodes_count(flow, count) do
    assert Enum.count(flow.nodes) == count
  end

  def assert_flow_nodes_match(flow, matches) do
    Enum.with_index(flow.nodes)
    |> Enum.map(
         fn  {{_,node}, index} ->
           assert_flow_node(node, get_in(matches, [Access.at(index)]))
         end
       )
  end

  def assert_flow_node(node, constraints) do
    Enum.map(constraints,
      fn
        {:id, value} ->
          assert_flow_node_id(node, value)
        {:outbound_links, constraints} -> assert_flow_node_outbound_links(node, constraints)
        {:inbound_links, constraints} -> assert_flow_node_inbound_links(node, constraints)
      end
    )
  end

  def assert_flow_node_id(node, value) do
    {:ok, id} = GenAI.Flow.NodeProtocol.id(node)
    assert id == value
  end


  def assert_flow_node_inbound_links(node, constraints) do
    Enum.map(constraints,
      fn
        {:count, {outlet, count}} ->
          assert Enum.count(node.inbound_links[outlet]) == count
        {:value, value} ->
          assert node.inbound_links == value
      end
    )
  end

  def assert_flow_node_outbound_links(node, constraints) do
    Enum.map(constraints,
      fn
        {:count, {outlet, count}} ->
          assert Enum.count(node.outbound_links[outlet]) == count
        {:value, value} ->
          assert node.outbound_links == value
      end
    )
  end



  def assert_flow_links(flow, constraints) do
    Enum.map(constraints,
      fn
        {:count, count} -> assert_flow_links_count(flow, count)
        {:match, match} -> assert_flow_links_match(flow, match)
      end
    )
  end

  def assert_flow_links_count(flow, count) do
    assert Enum.count(flow.links) == count
  end

  def assert_flow_links_match(flow, matches) do
    Enum.with_index(flow.links)
    |> Enum.map(
         fn  {{_,node}, index} ->
           assert_flow_link(node, get_in(matches, [Access.at(index)]))
         end
       )
  end

  def assert_flow_link(link, constraints) do
    Enum.map(constraints,
      fn
        {:id, value} ->
          assert_flow_link_id(link, value)
        {:target, value} ->
          assert_flow_link_target(link, value)
        {:source, value} ->
          assert_flow_link_source(link, value)
      end
    )
  end

  def assert_flow_link_source(link, value)
  def assert_flow_link_source(link, R.link_source() = value) do
    assert link.source == value
  end
  def assert_flow_link_source(link, value) when T.is_node_id(value) do
    {:ok, R.link_source(id: expected)} = GenAI.Flow.LinkProtocol.source(link)
    assert expected == value
  end

  def assert_flow_link_target(link, value)
  def assert_flow_link_target(link, R.link_target() = value) do
    assert link.target == value
  end
  def assert_flow_link_target(link, value) when T.is_node_id(value) do
    {:ok, R.link_target(id: expected)} = GenAI.Flow.LinkProtocol.target(link)
    assert expected == value
  end


  def assert_flow_link_id(link, value) do
    assert link.id == value
  end



  describe "define flow" do

    test "add multiple nodes to flow" do
      flow = Flow.new()
             |> Flow.add_node(Node.new(:node_1))
             |> Flow.add_node(Node.new(:node_2))

      assert_flow(flow,
        %{
          is_flow: true,
          nodes: [
            count: 2,
            match: [
              %{id: :node_1},
              %{id: :node_2}
            ]
          ]
        }
      )
    end


    test "add links" do
      sut = GenAI.Flow.new(id: :test_flow)
            |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_a))
            |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_b))
            |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_c))
            |> GenAI.Flow.add_node(GenAI.Flow.Node.new(:test_node_d))
            |> GenAI.Flow.add_link(GenAI.Flow.Link.new(:test_node_a, :test_node_b, id: :test_link_ab))
            |> GenAI.Flow.add_link(GenAI.Flow.Link.new(:test_node_a, :test_node_c, id: :test_link_ac))
            |> GenAI.Flow.add_link(GenAI.Flow.Link.new(:test_node_c, :test_node_d, id: :test_link_cd))
      assert_flow(sut,
        %{
          is_flow: true,
          nodes: [
            count: 4,
            match: [
              %{
                id: :test_node_a,
                outbound_links: %{
                  count: {:default, 2},
                  value: %{default: [:test_link_ac, :test_link_ab]}
                }
              },
              %{
                id: :test_node_b,
                inbound_links: %{
                  count: {:default, 1},
                  value: %{default: [:test_link_ab]}
                }
              },
              %{
                id: :test_node_c,
                inbound_links: %{
                  count: {:default, 1},
                  value: %{default: [:test_link_ac]}
                },
                outbound_links: %{
                  count: {:default, 1},
                  value: %{default: [:test_link_cd]}
                }
              },
              %{
                id: :test_node_d,
                inbound_links: %{
                  count: {:default, 1},
                  value: %{default: [:test_link_cd]}
                }
              }
            ]
          ],
          links: [
            count: 3,
            match: [
              %{id: :test_link_ab, source: :test_node_a, target: :test_node_b},
              %{id: :test_link_ac, source: :test_node_a, target: :test_node_c},
              %{id: :test_link_cd, source: :test_node_c, target: :test_node_d}
            ]
          ]
        }
      )
    end
  end
end