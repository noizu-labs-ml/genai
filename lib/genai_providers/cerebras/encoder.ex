defmodule GenAI.Provider.Cerebras.Encoder do
  @base_url "https://api.cerebras.ai"
  use GenAI.Model.EncoderBehaviour
  # Cerebras uses the OpenAI-default `/v1/chat/completions` endpoint — no override needed.
end
