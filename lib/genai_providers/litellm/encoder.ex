defmodule GenAI.Provider.LiteLLM.Encoder do
  use GenAI.Model.EncoderBehaviour

  # LiteLLM's base_url is deployment-specific (runtime config), so resolve it per call
  # rather than baking it in at compile time. OpenAI-compatible `/v1/chat/completions`.
  def endpoint(_model, _settings, session, _context, _options),
    do: {:ok, {{:post, "#{GenAI.Provider.LiteLLM.base_url()}/v1/chat/completions"}, session}}
end
