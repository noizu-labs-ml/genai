defmodule GenAI.Provider.OpenRouter.Encoder do
  @base_url "https://openrouter.ai/api"
  use GenAI.Model.EncoderBehaviour

  def stream_decoder, do: GenAI.StreamHandler.OpenAI

  def base_url(settings \\ []), do: GenAI.Provider.OpenRouter.base_url(settings)

  # OpenRouter's OpenAI-compat root is already `/api/v1`.
  def endpoint(_model, settings, session, _context, _options),
    do: {:ok, {{:post, "#{base_url(settings)}/chat/completions"}, session}}

  def headers(_model, settings, session, _context, options) do
    key = GenAI.Provider.OpenRouter.api_key(settings, options)
    cfg = Application.get_env(:genai, :openrouter, [])

    referer =
      get_setting(settings, :http_referer) || Keyword.get(cfg, :http_referer) ||
        "https://github.com/noizu-labs-ml/genai"

    title =
      get_setting(settings, :app_title) || Keyword.get(cfg, :app_title) || "Noizu GenAI"

    headers = [
      {"Authorization", "Bearer #{key}"},
      {"content-type", "application/json"},
      {"HTTP-Referer", referer},
      {"X-OpenRouter-Title", title},
      {"X-Title", title}
    ]

    {:ok, {headers, session}}
  end

  def default_hyper_params(_model, _settings, _session, _context, _options) do
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
      hyper_param(name: :provider),
      hyper_param(name: :reasoning),
      hyper_param(name: :response_format),
      hyper_param(name: :seed),
      hyper_param(name: :stop_sequence, as: :stop, type: :list),
      hyper_param(name: :stream, type: :boolean),
      hyper_param(name: :stream_options),
      hyper_param(name: :temperature),
      hyper_param(
        name: :tool_choice,
        type: :string,
        sentinel: fn _, body, _, _ -> body[:tools] && true end
      ),
      hyper_param(name: :top_logprobs),
      hyper_param(name: :top_p),
      hyper_param(name: :user)
    ]

    {:ok, x}
  end

  defp get_setting(settings, key) when is_map(settings) do
    present(get(settings[:model_settings], key)) ||
      present(get(settings[:provider_settings], key)) ||
      present(get(settings[:settings], key)) ||
      present(get(settings[:config_settings], key))
  end

  defp get_setting(settings, key) when is_list(settings), do: present(Keyword.get(settings, key))
  defp get_setting(_, _), do: nil

  defp get(nil, _key), do: nil
  defp get(src, key) when is_map(src), do: Map.get(src, key)
  defp get(src, key) when is_list(src) and is_atom(key), do: Keyword.get(src, key)
  defp get(_, _), do: nil

  defp present(v) when v in [nil, ""], do: nil
  defp present(v), do: v
end
