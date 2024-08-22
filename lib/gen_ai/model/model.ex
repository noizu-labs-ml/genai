defmodule GenAI.Model do
  @moduledoc """
  The GenAI.Model struct provides detailed information on a provider-model used for picking best model for job based on requirements.

  ## Details
  - Rate Limits/ Capacity
      - Requests Per Minute
      - Token Cap
 - Speed
      - Throughput (tokens per minute)
  - Cost
      - system memory - base + per context size costs
      - per 1000 input tokens
      - per 1000 output tokens
      - per attachment/file
      - per image by resolution
      - per video by resolution
      - per hour
      - per request
  - Media Support: OpenAI GPT-4o-mini for example does not support audio but video can be simulated with snapshots plus whisper transcription of audio contents.
      - Image
      - Video
      - Audio
  - Use Cases: Score/Capability at specific tasks/areas, both generic and fine tune specific end user use cases. Score includes both fixed/assumed values and system feedback/performance based dynamic scores.
      - Synthetic Memory Generation
      - Text Generation
      - Image Analysis
      - Audio Analysis
      - Planning
      - Intention Planning
      - Mind Mapping
      - Code Generation
      - Code Analysis
  - BenchMarks: Performance metrics from llms leader board
  - Fine Tune Details: Is the model fine tuned, if so what is the base model, and type of tuning.
  - Tool Use: Does the model support native tool usage, or capable enough to support tool usage via prompt injection.
  - Choices: Does the model support multi choice response lists
  - Tokens: Maximum tokens allowed for input and output - context windows size and generation size.
  - Settings - Hyperparameters, and other settings that can be set for the model.
    - Temperature
    - Top P
    - Top K
    - Frequency Penalty
    - Presence Penalty
    - Max Tokens
    - etc.
  - Supported Completion Type
      - Chat
      - Assistant
      - Image Generation
      - File Generation
      - Video Generation
  """

  @vsn 1.0
  defstruct [
    provider: nil,
    model: nil,
    details: nil,
    vsn: @vsn
  ]

  defimpl GenAI.ModelProtocol do
    def protocol_supported?(_), do: true
    def identifier(model), do: {:ok, model.model}
    def provider(model), do: {:ok, model.provider}
    def model(model), do: {:ok, model.model}
    def register(model, state), do: {:ok, {model, state}}
  end
end
