defmodule GenAI.Session.StateTest do
    use ExUnit.Case
    
    require GenAI.Session.Records
    import GenAI.Session.Records
    
    def context() do
        Noizu.Context.system()
    end
    
    @moduletag :work
    
    describe "Directive Resolution" do
        
        test "Does not Have Pending Directive" do
            state = %GenAI.Session.State{
                directives: []
            }
            assert GenAI.Session.State.pending_directives?(state) == false
        end
        
        test "Has Pending Directive" do
            directive = %GenAI.Session.State.Directive{
              id: 1000,
              source: {:node, 1},
              entries: [
                 selector(for: {:setting, :temperature}, value: {:concrete, 100})
              ]
            }
            state = %GenAI.Session.State{
              directives: [directive]
            }
            assert GenAI.Session.State.pending_directives?(state) == true
            
        end
        
        test "Concrete Setting" do
            directive = %GenAI.Session.State.Directive{
                id: 1000,
                source: {:node, 1},
                entries: [
                    selector(for: {:setting, :temperature}, value: {:concrete, 54})
                ]
            }
            state = %GenAI.Session.State{
                directives: [directive]
            }
            {:ok, {value, _}} = GenAI.Session.State.effective_setting(state, :temperature, context(), [])
            assert value == 54
        end
        
        test "Concrete Setting - not present" do
            directive = %GenAI.Session.State.Directive{
                id: 1000,
                source: {:node, 1},
                entries: [
                    selector(for: {:setting, :temperature}, value: {:concrete, 54})
                ]
            }
            state = %GenAI.Session.State{
                directives: [directive]
            }
            assert {:error, _}  = GenAI.Session.State.effective_setting(state, :temperature_two, context(), [])
        end
        
        test "Concrete Setting - not present, with default" do
            directive = %GenAI.Session.State.Directive{
                id: 1000,
                source: {:node, 1},
                entries: [
                    selector(for: {:setting, :temperature}, value: {:concrete, 54})
                ]
            }
            state = %GenAI.Session.State{
                directives: [directive]
            }
            assert {:ok, {:bob, _}}  = GenAI.Session.State.effective_setting(state, :temperature_two, :bob, context(), [])
        end
        
        
        test "Conditional Value By Option Setting" do
            directive = %GenAI.Session.State.Directive{
                id: 1000,
                source: {:node, 1},
                entries: [
                    selector(for: {:setting, :temperature}, value: {:concrete, 44})
                ]
            }
            
            
            directive2 = %GenAI.Session.State.Directive{
                id: 1001,
                source: {:node, 2},
                entries: [
                    selector(for: {:setting, :temperature}, value: {:lambda, fn(entry, state, context, options) ->
                                                                       with {:ok, {value, state}} <- GenAI.Session.State.effective_option(state, :analytic_mode, false, context(), options) do
                                                                           if value do
                                                                               {:ok, {{:concrete, 15}, state}}
                                                                           else
                                                                               {:ok, {:chain, state}}
                                                                           end
                                                                       end
                    end}),
                    selector(for: {:option, :analytic_mode}, value: {:concrete, false}),
                ]
            }
            state = %GenAI.Session.State{
                directives: [directive, directive2]
            }
            {:ok, {value, _}} = GenAI.Session.State.effective_setting(state, :temperature, context(), [])
            assert value == 15
        end
        
        test "Cascade If Conditional Value False" do
            directive = %GenAI.Session.State.Directive{
                id: 1000,
                source: {:node, 1},
                entries: [
                    selector(for: {:setting, :temperature}, value: {:concrete, 44})
                ]
            }
            
            
            directive2 = %GenAI.Session.State.Directive{
                id: 1001,
                source: {:node, 2},
                entries: [
                    selector(for: {:setting, :temperature}, value: {:lambda, fn(entry, state, context, options) ->
                                                                       with {:ok, {value, state}} <- GenAI.Session.State.effective_option(state, :analytic_mode, false, context(), options) do
                                                                           if value do
                                                                               {:ok, {{:concrete, 15}, state}}
                                                                           else
                                                                               {:ok, {:chain, state}}
                                                                           end
                                                                       end
                         
                    end}),
                    selector(for: {:option, :analytic_mode}, value: {:concrete, false}),
                ]
            }
            
            state = %GenAI.Session.State{
                directives: [directive]
            }
            {:ok, {value, _}} = GenAI.Session.State.effective_setting(state, :temperature, context(), [])
            assert value == 44
        end
        
        
    end
end