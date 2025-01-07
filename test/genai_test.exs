defmodule GenAITest do
  # import GenAI.Test.Support.Common
    use ExUnit.Case
    require Logger
    doctest GenAI

    def context() do
      Noizu.Context.system()
    end

    defmodule Fixtures do
        require Logger
        #--------------------------------
        # session/2
        #--------------------------------
        @doc """
        Thread Message Fixture
        """
        def session(session, scenario \\ :default)
        def session(session, :hal), do: session(session, :default)
        def session(session, :default) do
            session
            |> GenAI.with_message(GenAI.Message.system("You are a pop-culture literate funny and amusing assistant"))
            |> GenAI.with_message(GenAI.Message.user("Open the pod bay door HAL"))
            |> GenAI.with_message(GenAI.Message.assistant("I'm afraid I can't do that Dave"))
            |> GenAI.with_message(GenAI.Message.user("What is the movie \"2001: A Space Odyssey\" about and who directed it?"))
        end
        def session(session, :multi_set) do
            session
            |> GenAI.with_messages([
                GenAI.Message.system("You are a pop-culture literate funny and amusing assistant"),
                GenAI.Message.user("Open the pod bay door HAL"),
                GenAI.Message.assistant("I'm afraid I can't do that Dave"),
                GenAI.Message.user("What is the movie \"2001: A Space Odyssey\" about and who directed it?")
            ])
        end
        def session(session, unsupported_scenario) do
            Logger.warning("Unsupported Thread Fixture Scenario: #{unsupported_scenario}")
            session(session, :default)
        end
        
        def settings(session, scenario \\ :default)
        def settings(session, :hal), do: settings(session, :default)
        def settings(session, :multi_set) do
            session
            |> GenAI.with_settings([temperature: 0.8, max_tokens: 2048, top_p: 0.8])
        end
        def settings(session, :default) do
            session
            |> GenAI.with_setting(:temperature, 0.7)
            |> GenAI.with_setting(:max_tokens, 4096)
            |> GenAI.with_setting(:top_p, 0.9)
        end
        def settings(session, unsupported_scenario) do
            Logger.warning("Unsupported Settings Fixture Scenario: #{unsupported_scenario}")
            settings(session, :default)
        end
        
        def model_selector(session, scenario \\ :default)
        def model_selector(session, :hal) do
            model_selector(session, :default)
        end
        def model_selector(session, :multi_set) do
            model_selector(session, :default)
        end
        def model_selector(session, :default) do
            session
            |> GenAI.with_model(GenAI.Provider.TestProvider.Models.test_model())
            |> GenAI.with_api_key(GenAI.Provider.TestProvider, "test-api-key")
        end
        def model_selector(session, unsupported_scenario) do
            Logger.warning("Unsupported Model Fixture Scenario: #{unsupported_scenario}")
            model_selector(session, :default)
        end
        
        
        def tools(session, scenario \\ :default)
        def tools(session, _) do
            session
        end
    end
    
    # State Module
    # - apply
    # - effective settings
    # - effective model
    # Apply Node
    describe "Session Graph API" do
      @describetag :wip
      setup do
        GenAI.Config.reset(:global)
        :ok
      end

      test "Apply Setting" do
        setting = %GenAI.Setting{
          id: UUID.uuid4(),
          setting: :max_tokens,
          value: 4096
        }

        sut = GenAI.chat()
              |> GenAI.with_setting(setting)
      end
    end



    describe "Session Configuration" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
        
        test "New Session" do
            sut = GenAI.chat()
            assert sut.graph.__struct__ == GenAI.Graph
            assert sut.state.__struct__ == GenAI.Session.State
        end
        
        test "Static Setting" do
            sut = GenAI.chat()
                  |> GenAI.with_setting(:max_tokens, 4096)
                  |> GenAI.execute(:report, context())
            
        end


        @tag :wip2
        test "Simple Flow - With Tool Usage" do
          scenario = :tool_usage
          session = GenAI.chat()
                    |> Fixtures.session(scenario)
                    |> Fixtures.settings(scenario)
                    |> Fixtures.model_selector(scenario)
                    |> Fixtures.tools(scenario)
          Process.sleep(400)
          IO.puts "--------------"
          {:ok, sut} = GenAI.execute(session, :report, context())
          assert sut == :pending2
        end


    end
    
    
    describe "Basic Flow" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
        
        test "Simple Flow - Multi Set" do
            scenario = :multi_set
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
        
        test "Simple Flow - interleaved settings,model,message populate" do
            session = GenAI.chat()
                     |> GenAI.with_message(GenAI.Message.system("You are a pop-culture literate funny and amusing assistant"))
                     |> GenAI.with_setting(:max_tokens, 4096)
                     |> GenAI.with_message(GenAI.Message.user("Open the pod bay door HAL"))
                     |> GenAI.with_model(GenAI.Provider.TestProvider.Models.test_model())
                     |> GenAI.with_setting(:temperature, 0.7)
                     |> GenAI.with_message(GenAI.Message.assistant("I'm afraid I can't do that Dave"))
                     |> GenAI.with_api_key(GenAI.Provider.TestProvider, "test-api-key")
                     |> GenAI.with_setting(:top_p, 0.9)
                     |> GenAI.with_message(GenAI.Message.user("What is the movie \"2001: A Space Odyssey\" about and who directed it?"))
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
        
        test "Simple Flow - Run" do
            scenario = :hal
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
        
        test "Simple Flow - Stream" do
            scenario = :hal
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
            {:ok, sut} = GenAI.stream(session, context())
            assert sut == :pending
        end
        
        test "Simple Flow - Stream - override handler" do
            scenario = :hal
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
                     |> GenAI.with_stream_handler(GenAI.StreamHandler.TestHandler)
            {:ok, sut} = GenAI.stream(session, context())
            assert sut == :pending
        end
        
        test "Simple Flow - Execute" do
            scenario = :hal
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
            {:ok, sut} = GenAI.execute(session, :report, context())
            assert sut == :pending2
        end



    end
    
    describe "Flow Setting Options" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
      # cover all settings.
    end
    
    describe "Flow with Tool Usage" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
        
        test "Simple Flow - With Tool Usage" do
            scenario = :tool_usage
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
                     |> Fixtures.tools(scenario)
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
        
        test "Simple Flow - With Tool Usage - with model toggle" do
            scenario = :tool_usage
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
                     |> Fixtures.tools(scenario)
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
    
    end
    
    describe "Multi Modal Flow" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
        
        # test image/video/file/audio input
        test "Text & Image Input - Run" do
            scenario = :text_image_in
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
        
        test "Text & Image Output - Run" do
            scenario = :text_image_out
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
        
        test "Text & Audio Input - Run" do
            scenario = :text_audio_in
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
        
        test "Text & Audio Output - Run" do
            scenario = :text_audio_out
            session = GenAI.chat()
                     |> Fixtures.session(scenario)
                     |> Fixtures.settings(scenario)
                     |> Fixtures.model_selector(scenario)
            {:ok, sut} = GenAI.run(session, context())
            assert sut == :pending
        end
    
    
    end
    
    describe "Dynamic Flow" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
      
      # test flow with runtime generated prompts / dynamic prompts
    end
    
    describe "Flow Prompt Tuning" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
      
      # test flow with prompt fine tuning loop
    end
    
    describe "Flow Rubrix Loop" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
      
      # test flow with loop until rubrix met or exceeded check
    end
    
    describe "Flow with Dynamic Setting/Model Selection" do
        setup do
            GenAI.Config.reset(:global)
            :ok
        end
      
      # test flow with dynamic setting/model selection based on requirements.
    end

end
