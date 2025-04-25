defmodule GenAI.Provider.OpenAI.Encoder do
  use GenAI.Model.EncoderBehaviour
  
  def headers(model, settings, session, context, options) do
    with {:ok, {headers, session}} <- super(model, settings, session, context, options) do
      search_scope = [
        options,
        settings[:model_settings],
        settings[:provider_settings],
        settings[:settings],
        settings[:config_settings],
      ]
      
      headers = search_scope
                |> Enum.find_value(& &[:api_org])
                |> then(& &1 && [{"OpenAI-Organization", &1} | headers] || headers)
      headers = search_scope
                |> Enum.find_value(& &[:api_project])
                |> then(& &1 && [{"OpenAI-Project", &1} | headers] || headers)
      {:ok, {headers, session}}
    end
  end
  
end