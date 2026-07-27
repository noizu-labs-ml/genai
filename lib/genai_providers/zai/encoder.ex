defmodule GenAI.Provider.ZAI.Encoder do
  @base_url "https://api.z.ai"
  use GenAI.Model.EncoderBehaviour

  def endpoint(_, _, session, _, _),
    do: {:ok, {{:post, "#{@base_url}/api/paas/v4/chat/completions"}, session}}
end
