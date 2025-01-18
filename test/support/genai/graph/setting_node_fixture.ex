#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Fixture.Session do
    require GenAI.Session.Records
    alias GenAI.Session.Records, as: S
    require GenAI.Session.NodeProtocol.Records
    alias GenAI.Session.NodeProtocol.Records, as: N
    
    def context() do
        Noizu.Context.system()
    end
    
    defmodule Node do
        @vsn 1.0
        @moduledoc false
        require GenAI.Session.Records
        alias GenAI.Session.Records, as: S
        use GenAI.Graph.NodeBehaviour
        @derive GenAI.Graph.NodeProtocol
        @derive GenAI.Graph.NodeProtocol
#        @derive {
#            GenAI.Session.NodeProtocol,
#            input: %{
#                ohmy: S.data_set(name: :bob, records: 1),
#                apple: S.stack(item: :global_loon),
#                not_in_finger_print: GenAI.Session.Records.no_finger_print(S.stack(item: :foo_bop))
#            },
#            finger_print: %{
#                five_second_update: S.time_bucket([seconds: 5])
#
#            }
#        }
        
        
        
        defnodetype [
            setting: term,
            value: term,
        ]
        
        defnodestruct [
            setting: nil,
            value: nil,
        ]
        
        def node_type(%__MODULE__{}), do: GenAI.TestFixture
        
        def new(options \\ nil)
        def new(options) do
            %__MODULE__{
                setting: :apple,
                value: :steam
            }
        end
    
    
    end

    def scenario(scenario \\ :default, options \\ nil)
    
    def scenario(_, _) do
        directive = %GenAI.Session.State.Directive{
            id: 1000,
            source: {:node, 1},
            entries: [
                S.selector(for: {:setting, :temperature}, value: {:concrete, 44})
            ]
        }
        
        virtual_directive = %GenAI.Session.State.Directive{
            id: 1002,
            source: {:selector, {{:setting, :temperature}, 5555}},
            entries: [
                S.selector(for: {:option, :reply_mode}, value: {:concrete, :analytic_summary})
            ]
        }
        
        directive2 = %GenAI.Session.State.Directive{
            id: 1001,
            source: {:node, 2},
            entries: [
                S.selector(
                    id: 5555,
                    for: {:setting, :temperature},
                    impacts: {:option, :reply_mode},
                    references: {:options, :analytic_mode},
                    value: {:lambda, fn(entry, state, context, options) ->
                                         with {:ok, {value, state}} <- GenAI.Session.State.effective_option(state, :analytic_mode, false, context, options) do
                                             if value do
                                                 state = GenAI.Session.State.append_directive(state, virtual_directive, context, options)
                                                 {:ok, {{:concrete, 15}, state}}
                                             else
                                                 {:ok, {:chain, state}}
                                             end
                                         end
                    end}),
                S.selector(for: {:option, :analytic_mode}, value: {:concrete, true}),
            ]
        }
        session_state = %GenAI.Session.State{
            directives: [directive, directive2],
            data_generators: %{
                bob: GenAI.DataGenerator.new(), # todo directive logic for manipulating.
            },
            stack: %{global_loon: %GenAI.Session.StateEntry{state: %{foo: 1, bar: :bop}, finger_print: 777_000, inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()}},
        }
        graph_container = GenAI.Graph.new()
        session_runtime = GenAI.Session.Runtime.new()
        graph_node = GenAI.Fixture.Session.Node.new()
        
        N.scope(
            graph_node: graph_node,
            graph_link: nil,
            graph_container: graph_container,
            session_state: session_state,
            session_runtime: session_runtime
        )
        
        
    end

end

