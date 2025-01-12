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
        
        
        
    end
end