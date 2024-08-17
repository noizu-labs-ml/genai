defmodule GenAI.ModelDetail.Capacity do
  @moduledoc """
  Provides standardized structure for tracking capacity details.

  - requests per minute
  - tokens per minute
  - tokens per day
  - inference_speed
  - vram
  """

  @vsn 1.0
  @type t ::
          %__MODULE__{
            tokens_per_minute: integer | nil,
            requests_per_minute: integer | nil,
            tokens_per_day: integer | nil,
            inference_speed: integer | nil,
            tokens_per_minute: integer | nil,
               vsn: float
          }
  defstruct [
    tokens_per_minute: nil,
    requests_per_minute: nil,
    tokens_per_day: nil,
    inference_speed: nil,
    vram: nil,
    vsn: @vsn
  ]
end

defmodule GenAI.ModelDetail.Costing do
  @moduledoc """
    Provides standardized structure for tracking costing details.
    - cost per million input tokens
    - cost per million output tokens
    - cost per hour
    - cost per request
    - media costs
    """
  @vsn 1.0
  @type t ::
          %__MODULE__{
            million_input_tokens: float | nil,
            million_output_tokens: float | nil,
            per_request: float | nil,
            per_instance_hour: float | nil,
            media: Map.t | nil, # tile_size, base_tokens, tokens_per_tile
            vsn: float
          }
  defstruct [
    million_input_tokens: nil,
    million_output_tokens: nil,
    per_request: nil,
    per_instance_hour: nil,
    media: nil,
    vsn: @vsn
  ]
end

defmodule GenAI.ModelDetail.ModalitySupport do
  @moduledoc """
  Provides standardized structure for tracking modality support details.
    For example if a model can mimic video support by streaming images,
    plus audio transcription. Or supports native image and audio.
  """
  @vsn 1.0
  @type t ::
          %__MODULE__{
            video: any,
            image: any,
            audio: any,
            vsn: float
          }
  defstruct [
    video: nil,
    image: nil,
    audio: nil,
    vsn: @vsn
  ]
end

defmodule GenAI.ModelDetail.ToolUsage do
  @moduledoc """
  Provides details on tool usage support: native (api level), prompt injection, no support, etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct [vsn: @vsn]
end


defmodule GenAI.ModelDetail.UseCaseSupport do
  @moduledoc """
  Provides standardized structure for tracking use case support details.
  Where use case is the ability of the model to perform a task like feature extraction, generating synthetic memories, etc.
  Tracks both per model fixed scores plus dynamic adjustments based on system/user feedback.
  """
  @vsn 1.0
  @type t :: %__MODULE__{
               use_cases: Map.t,
               vsn: float
             }
  defstruct [
    use_cases: %{},
    vsn: @vsn
  ]
end

defmodule GenAI.ModelDetail.BenchMarks do
  @moduledoc """
  Last reported model evaluation benchmark scores.
  """
  @vsn 1.0
  @type t :: %__MODULE__{
               benchmarks: Map.t,
               vsn: float
             }
  defstruct [
    benchmarks: %{},
    vsn: @vsn
  ]
end

defmodule GenAI.ModelDetail.FineTuning do
  @moduledoc """
  Tracks fine tuning details for the model, if any.
  - Type of fine tuning
  - Fine Tuning Date
 - Fine Tuning Notes
  """

  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct [vsn: @vsn]
end

defmodule GenAI.ModelDetail.HyperParamSupport do
  @moduledoc """
  Provides standardized structure for tracking hyper parameter support such as allowed values, ranges, mapping etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct [vsn: @vsn]
end

defmodule GenAI.ModelDetail.TrainingDetails do
  @moduledoc """
  Provides standardized structure for tracking training details such as training cut off, supplemental_training per subject cut offs, etc. censorship. instruct training, dolphin, etc.
  """
  @vsn 1.0
  @type t :: %__MODULE__{vsn: float}
  defstruct [vsn: @vsn]
end

defmodule GenAI.ModelDetails do
  @moduledoc """
  Provides standardized structure for tracking extended module details.
  """
  @vsn 1.0
  @type release_status :: :internal | :alpha | :beta | :rc | :stable | :deprecated | nil
  @type support_status :: :supported | :unsupported | :partial | :unknown | nil
  @type capacity :: GenAI.ModelDetail.Capacity.t | nil
  @type costing :: GenAI.ModelDetail.Costing.t | nil
  @type modalities :: GenAI.ModelDetail.ModalitySupport.t | nil
  @type tool_usage :: GenAI.ModelDetail.ToolUsage.t | nil
  @type use_case_support :: GenAI.ModelDetail.UseCaseSupport.t | nil
  @type benchmarks :: GenAI.ModelDetail.BenchMarks.t | nil
  @type fine_tuning :: GenAI.ModelDetail.FineTuning.t | nil
  @type hyper_param_support :: GenAI.ModelDetail.HyperParamSupport.t | nil
  @type training_details :: GenAI.ModelDetail.TrainingDetails.t | nil

  @type t ::
          %__MODULE__{
            release: release_status,
            status: support_status,
            capacity: capacity,
            costing: costing,
            modalities: modalities,
            tool_usage: tool_usage,
            use_cases: use_case_support,
            benchmarks: benchmarks,
            fine_tuning: fine_tuning,
            hyper_params: hyper_param_support,
            training_details: training_details,
            vsn: float
          }

  defstruct [
    release: nil,
    status: nil,
    capacity: nil,
    costing: nil,
    modalities: nil,
    tool_usage: nil,
    use_cases: nil,
    benchmarks: nil,
    fine_tuning: nil,
    hyper_params: nil,
    training_details: nil,
    vsn: @vsn
  ]



end

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

defmodule GenAI.ExternalModel do
  @vsn 1.0
  @enforce_keys [:handle, :manager]
  defstruct [
    handle: nil,
    provider: nil,

    manager: nil,
    external: nil,
    configuration: nil,

    details: nil,
    vsn: @vsn
  ]

  defimpl GenAI.ModelProtocol do
    def protocol_supported?(_), do: true
    def identifier(model), do: {:ok, model.handle}
    def provider(model), do: {:ok, model.provider}
    def model(model) do
      IO.puts "TODO: fetch live model from manager"
      {:ok, model}
    end
    def register(model, state), do: {:ok, {model, state}}
  end
end
