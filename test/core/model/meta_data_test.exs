defmodule GenAI.Model.MetaDataTest do
  use ExUnit.Case
  @moduletag :core
  doctest GenAI.Model.MetaData.Helper

  def metadata(scenario \\ :valid)
  def metadata(:valid) do
    YamlElixir.read_all_from_string!(
      """
      genai_metadata:
        version: 0.1
        providers:
          - name: openai
            models:
              - model: gpt4o
                description: OpenAI's GPT-4 model
                capacity:
                  context_window: 128000
                  max_output_tokens: 4096
                  requests_per_minute:
                      free: 100
                      tier_1: 1000
                      tier_2: 1000
                      tier_3: 1000
                      tier_4: 1000
                      tier_5: 1000
              - model: gpt4o-mini
                description: OpenAI's GPT-4 model
                capacity:
                  context_window: 128000
                  max_output_tokens: 4096
                  requests_per_minute:
                    free: 100
                    tier_1: 1000
                    tier_2: 1000
                    tier_3: 1000
                    tier_4: 1000
                    tier_5: 1000
      """
    ) |> hd()

  end
  def metadata(:invalid), do: %{}


  test "Load Meta Data From Disk" do
    sut = GenAI.Model.MetaData.load()
    assert sut == :wip
  end


  describe "Extract Segment" do

    test "Supported Value" do
      {:ok, sut} = GenAI.Model.MetaData.extract_segment(metadata(:valid))
      %GenAI.Model.MetaData.Entry{version: version} = sut
      assert version == 0.1
      #IO.inspect(sut, label: "SUT")
    end

    test "Unsupported Segment" do
      sut = GenAI.Model.MetaData.extract_segment(metadata(:invalid))
      assert {:error, {:unsupported_segment, _}} = sut
    end

  end


end
