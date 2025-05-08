defmodule GenAI.Provider.Groq.Encoder do
  @base_url "https://api.groq.com/openai"
  use GenAI.Model.EncoderBehaviour
  
  def default_hyper_params(model, settings, session, context, options)
  def default_hyper_params(model, settings, session, context, options) do
    x = [
      hyper_param(name: :frequency_penalty),
      hyper_param(name: :logit_bias),
      hyper_param(name: :logprobs),
      hyper_param(name: :max_tokens, type: :integer),
      hyper_param(name: :max_completion_tokens, type: :integer),
      hyper_param(name: :metadata),
      hyper_param(name: :completion_choices, as: :n),
      hyper_param(name: :parallel_tool_calls, type: :boolean),
      hyper_param(name: :presence_penalty),
      hyper_param(name: :reasoning_format),
      hyper_param(name: :response_format),
      hyper_param(name: :seed),
      hyper_param(name: :service_tier),
      hyper_param(name: :stop_sequence, as: :stop, type: :list),
      hyper_param(name: :store),
      hyper_param(name: :stream, type: :boolean),
      hyper_param(name: :stream_options),
      hyper_param(name: :temperature),
      hyper_param(name: :tool_choice, type: :string, sentinel: fn(_, body, _, _) -> body[:tools] && true end),
      hyper_param(name: :top_logprobs),
      hyper_param(name: :top_p),
      hyper_param(name: :user),
    ]
    {:ok, x}
  end

end
