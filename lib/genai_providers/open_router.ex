defmodule GenAI.Provider.OpenRouter do
  @moduledoc """
  OpenRouter inference provider (`https://openrouter.ai/api/v1`).

  OpenAI-compatible chat and `GET /models`. Bearer auth from
  `config :genai, :openrouter, api_key:` (`OPENROUTER_API_KEY`). Optional
  attribution headers: `http_referer` (`HTTP-Referer`) and `app_title`
  (`X-OpenRouter-Title` / `X-Title`).
  """
  @base_url "https://openrouter.ai/api"
  @config_key :openrouter
  use GenAI.InferenceProviderBehaviour

  @doc "OpenAI-compatible API root (`…/api/v1`). Per-request `:base_url` still wins."
  def base_url(settings \\ [])

  def base_url(settings) do
    ctx = normalize_settings(settings)
    request_get(ctx, :base_url) || config_get(ctx, :base_url) || "#{@base_url}/v1"
  end

  @doc "Bearer token (`api_key` / `OPENROUTER_API_KEY`)."
  def api_key(settings \\ [], options \\ [])

  def api_key(settings, options) do
    ctx = normalize_settings(settings)

    present(get(options, :api_key)) || request_get(ctx, :api_key) || find_get(ctx, :api_key) ||
      raise GenAI.RequestError, message: "API KEY NOT FOUND - #{__MODULE__}"
  end

  @doc "Retrieves models from OpenRouter `GET /api/v1/models`."
  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{base_url(settings)}/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      decode_models(json)
    end
  end

  # OpenRouter omits OpenAI's `object: "list"`; payload is `data` + `total_count`.
  defp decode_models(%{data: models}) when is_list(models),
    do: {:ok, Enum.map(models, &model_from_json/1)}

  defp decode_models(json), do: {:error, {:response, json}}

  defp model_from_json(json) do
    %GenAI.Model{
      model: json[:id],
      provider: __MODULE__,
      details: json
    }
  end

  defp normalize_settings(settings) when is_list(settings) do
    %{
      settings: settings,
      config_settings: Application.get_env(:genai, :openrouter, [])
    }
  end

  defp normalize_settings(settings) when is_map(settings) do
    Map.put_new(settings, :config_settings, Application.get_env(:genai, :openrouter, []))
  end

  defp normalize_settings(_), do: %{config_settings: Application.get_env(:genai, :openrouter, [])}

  defp request_get(ctx, key) do
    present(get(ctx[:model_settings], key)) ||
      present(get(ctx[:provider_settings], key)) ||
      present(get(ctx[:settings], key))
  end

  defp config_get(ctx, key), do: present(get(ctx[:config_settings], key))

  defp find_get(ctx, key) do
    request_get(ctx, key) || config_get(ctx, key)
  end

  defp get(nil, _key), do: nil
  defp get(src, key) when is_map(src), do: Map.get(src, key)
  defp get(src, key) when is_list(src) and is_atom(key), do: Keyword.get(src, key)
  defp get(_, _), do: nil

  defp present(v) when v in [nil, ""], do: nil
  defp present(v), do: v
end
