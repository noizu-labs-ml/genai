defmodule GenAI.Provider.Mistral.Encoder do
  
  
  def default_hyper_params(model, settings, session, context, options)
  def default_hyper_params(model, settings, session, context, options) do
    x = [
      hyper_param(name: :temperature),
      hyper_param(name: :top_p),
      hyper_param(name: :max_tokens, type: :integer),
      hyper_param(name: :stream, type: :boolean),
      hyper_param(name: :stop_sequence, as: :stop, type: :list),
      hyper_param(name: :seed, as: :random_seed),
      hyper_param(name: :response_format, type: :map),
      hyper_param(name: :tool_choice, type: :string, sentinel: fn(_, body, _, _) -> body[:tools] && true end),
      hyper_param(name: :presence_penalty),
      hyper_param(name: :frequency_penalty),
      hyper_param(name: :completion_choices, as: :n),
      hyper_param(name: :prediction, type: :map),
      hyper_param(name: :parallel_tool_calls, type: :boolean),
      hyper_param(name: :safe_prompt, type: :boolean),
    ]
    {:ok, x}
  end
  
end
