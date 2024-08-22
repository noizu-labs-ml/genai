defmodule GenAI.Model.Details do
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
