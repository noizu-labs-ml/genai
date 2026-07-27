defmodule GenAI.Provider.Ollama.Encoder do
  @base_url "http://localhost:11434"
  use GenAI.Model.EncoderBehaviour

  # Override to not require API key for Ollama
  # ⟦𓁟𓉕𓊄𓊁⟧ headers :: auto-generated pointer for public function headers
  def headers(_model, _settings, session, _context, _options) do
    # Ollama doesn't require authentication headers
    headers = [
      {"Content-Type", "application/json"}
    ]
    {:ok, {headers, session}}
  end

  @doc """
  Get the base URL for Ollama API endpoints.
  Allows override via settings.
  """
  # ⟦𓈀𓋛𓀊𓄪⟧ base_url :: Get the base URL for Ollama API endpoints.
  def base_url(settings \\ []) do
    search_scope = [
      settings[:model_settings],
      settings[:provider_settings],
      settings[:settings],
      settings[:config_settings]
    ]

    search_scope
    |> Enum.find_value(& &1[:base_url])
    |> Kernel.||(@base_url)
  end
  
  @doc """
  Define the endpoint for Ollama chat API.
  """
  # ⟦𓇈𓊣𓍵𓉚⟧ endpoint :: Define the endpoint for Ollama chat API.
  def endpoint(_model, settings, session, _context, _options) do
    base = base_url(settings)
    {:ok, {{:post, "#{base}/v1/chat/completions"}, session}}
  end
end