defmodule GenAI.Provider.Anthropic.Encoder do
  @base_url "https://api.anthropic.com"
  use GenAI.Model.EncoderBehaviour
  
  def endpoint(model, settings, session, context, options)
  def endpoint(_, _, session ,_ ,_),
      do: {:ok, {{:post, "#{@base_url}/v1/messages"}, session}}
  
  def headers(model, settings, session, context, options) do
    
      search_scope = [
        options,
        settings[:model_settings],
        settings[:provider_settings],
        settings[:settings],
        settings[:config_settings],
      ]
    
      headers = [{"content-type", "application/json"}]
      headers = search_scope
                |> Enum.find_value(& &1[:anthropic_beta])
                |> then(& &1 && [{"anthropic-beta", &1} | headers] || headers)
      headers = search_scope
                |> Enum.find_value(& &1[:anthropic_version])
                |> then(&  [{"anthropic-version", &1 || "2023-06-01"} | headers])
      headers = search_scope
                |> Enum.find_value(& &1[:api_key])
                |> then(& &1 && [{"x-api-key", &1} | headers] || headers)
      
      {:ok, {headers, session}}
    
  end
  
  def default_hyper_params(model, settings, session, context, options)
  def default_hyper_params(model, settings, session, context, options) do
    x = [
      
      hyper_param(name: :max_tokens),
      hyper_param(name: :metadata),
      hyper_param(name: :stop_sequence),
      hyper_param(name: :stream),
      hyper_param(name: :system_prompt, as: :system),
      hyper_param(name: :temperature),
      hyper_param(name: :thinking),
      hyper_param(name: :tool_choice),
      
      hyper_param(name: :top_k),
      hyper_param(name: :top_p),
    ]
    {:ok, x}
  end

end
