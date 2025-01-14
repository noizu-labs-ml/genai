#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================


defmodule GenAI.Session.NodeProtocolTest do
    use ExUnit.Case
    require GenAI.Session.Records
    alias GenAI.Session.Records, as: S
    require GenAI.Session.Node.Records
    alias GenAI.Session.Node.Records, as: Node
    
    
    def context() do
        Noizu.Context.system()
    end

    
    describe "Node Protocol Core Logic" do
        
        test "Node derive option passing" do
            context = context()
            scope = Node.scope(graph_node: graph_node) = GenAI.Fixture.Session.scenario()
            x = GenAI.Session.NodeProtocol.graph_node_protocol_options(graph_node, context, [])
            assert  S.stack(item: :global_loon) = x.input.apple
            assert  {{:__genai__, :no_finger_print}, S.stack(item: :foo_bop)} = x.input.not_in_finger_print
            assert  S.time_bucket(seconds: 5) = x.finger_print.five_second_update
        end
        
        test "Automatic Data Pull from Derive" do
            context = context()
            scope = Node.scope(graph_node: graph_node) = GenAI.Fixture.Session.scenario()
            {:ok, {input, scope}} =  GenAI.Session.NodeProtocol.update_state_input(graph_node, scope, context, [])
            IO.inspect(input, label: "UNPACKED INPUT")
            
        end
    
    end
end