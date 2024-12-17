defmodule GenAITest do
  # import GenAI.Test.Support.Common
  use ExUnit.Case
  require Logger
  doctest GenAI


  defmodule Fixtures do
    #--------------------------------
    # thread/2
    #--------------------------------
    @doc """
    Thread Message Fixture
    """
    def thread(thread, scenario \\ :default)
    def thread(thread, :hal), do: thread(thread, :default)
    def thread(thread, :default) do
      thread
      |> GenAI.with_message(GenAI.Message.system("You are a pop-culture literate funny and amusing assistant"))
      |> GenAI.with_message(GenAI.Message.user("Open the pod bay door HAL"))
      |> GenAI.with_message(GenAI.Message.assistant("I'm afraid I can't do that Dave"))
      |> GenAI.with_message(GenAI.Message.user("What is the movie \"2001: A Space Odyssey\" about and who directed it?"))
    end
    def thread(thread, :multi_set) do
      thread
      |> GenAI.with_messages([
        GenAI.Message.system("You are a pop-culture literate funny and amusing assistant"),
        GenAI.Message.user("Open the pod bay door HAL"),
        GenAI.Message.assistant("I'm afraid I can't do that Dave"),
        GenAI.Message.user("What is the movie \"2001: A Space Odyssey\" about and who directed it?")
      ])
    end
    def thread(thread, unsupported_scenario) do
      Logger.warning("Unsupported Thread Fixture Scenario: #{unsupported_scenario}")
      thread(thread, :default)
    end

    def settings(thread, scenario \\ :default)
    def settings(thread, :hal), do: settings(thread, :default)
    def settings(thread, :multi_set) do
      thread
      |> GenAI.with_settings([temperature: 0.8, max_tokens: 2048, top_p: 0.8])
    end
    def settings(thread, :default) do
      thread
      |> GenAI.with_setting(:temperature, 0.7)
      |> GenAI.with_setting(:max_tokens, 4096)
      |> GenAI.with_setting(:top_p, 0.9)
    end
    def settings(thread, unsupported_scenario) do
      Logger.warning("Unsupported Settings Fixture Scenario: #{unsupported_scenario}")
      settings(thread, :default)
    end

    def model_selector(thread, scenario \\ :default)
    def model_selector(thread, :hal) do
      model_selector(thread, :default)
    end
    def model_selector(thread, :multi_set) do
      model_selector(thread, :default)
    end
    def model_selector(thread, :default) do
      thread
      |> GenAI.with_model(GenAI.Provider.TestProvider.Models.test_model())
      |> GenAI.with_api_key(GenAI.Provider.TestProvider, "test-api-key")
    end
    def model_selector(thread, unsupported_scenario) do
      Logger.warning("Unsupported Model Fixture Scenario: #{unsupported_scenario}")
      model_selector(thread, :default)
    end


    def tools(thread, scenario \\ :default)
    def tools(thread, _) do
      thread
    end
  end


  describe "Basic Flow" do
    setup do
      GenAI.Config.reset(:global)
      :ok
    end

    test "Simple Flow - Multi Set" do
      scenario = :multi_set
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
      {:ok, sut} = GenAI.run(thread)
      assert sut == :pending
    end

    test "Simple Flow - interleaved settings,model,message populate" do
      thread = GenAI.chat()
               |> GenAI.with_message(GenAI.Message.system("You are a pop-culture literate funny and amusing assistant"))
               |> GenAI.with_setting(:max_tokens, 4096)
               |> GenAI.with_message(GenAI.Message.user("Open the pod bay door HAL"))
               |> GenAI.with_model(GenAI.Provider.TestProvider.Models.test_model())
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_message(GenAI.Message.assistant("I'm afraid I can't do that Dave"))
               |> GenAI.with_api_key(GenAI.Provider.TestProvider, "test-api-key")
               |> GenAI.with_setting(:top_p, 0.9)
               |> GenAI.with_message(GenAI.Message.user("What is the movie \"2001: A Space Odyssey\" about and who directed it?"))
      {:ok, sut} = GenAI.run(thread)
      assert sut == :pending
    end

    test "Simple Flow - Run" do
      scenario = :hal
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
      {:ok, sut} = GenAI.run(thread)
      assert sut == :pending
    end

    test "Simple Flow - Stream" do
      scenario = :hal
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
      {:ok, sut} = GenAI.stream(thread)
      assert sut == :pending
    end

    test "Simple Flow - Stream - override handler" do
      scenario = :hal
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
               |> GenAI.with_stream_handler(GenAI.StreamHandler.TestHandler)
      {:ok, sut} = GenAI.stream(thread)
      assert sut == :pending
    end

    test "Simple Flow - Execute" do
      scenario = :hal
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
      {:ok, sut} = GenAI.execute(thread, :report)
      assert sut == :pending
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
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
               |> Fixtures.tools(scenario)
      {:ok, sut} = GenAI.run(thread)
      assert sut == :pending
    end

    test "Simple Flow - With Tool Usage - with model toggle" do
      scenario = :tool_usage
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
               |> Fixtures.tools(scenario)
      {:ok, sut} = GenAI.run(thread)
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
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
      {:ok, sut} = GenAI.run(thread)
      assert sut == :pending
    end

    test "Text & Image Output - Run" do
      scenario = :text_image_out
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
      {:ok, sut} = GenAI.run(thread)
      assert sut == :pending
    end

    test "Text & Audio Input - Run" do
      scenario = :text_audio_in
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
      {:ok, sut} = GenAI.run(thread)
      assert sut == :pending
    end

    test "Text & Audio Output - Run" do
      scenario = :text_audio_out
      thread = GenAI.chat()
               |> Fixtures.thread(scenario)
               |> Fixtures.settings(scenario)
               |> Fixtures.model_selector(scenario)
      {:ok, sut} = GenAI.run(thread)
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
