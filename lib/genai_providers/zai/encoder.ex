defmodule GenAI.Provider.ZAI.Encoder do
  @base_url "https://api.z.ai/api/paas/v4"
  use GenAI.Model.EncoderBehaviour

  # Z.AI's OpenAI-compatible chat path is `/chat/completions` (under /api/paas/v4),
  # not the OpenAI default `/v1/chat/completions`.
  # ⟦𓍗𓈁𓁣𓈶⟧ endpoint :: auto-generated pointer for public function endpoint
  def endpoint(_model, _settings, session, _context, _options),
    do: {:ok, {{:post, "#{@base_url}/chat/completions"}, session}}
end
