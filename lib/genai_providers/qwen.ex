defmodule GenAI.Provider.Qwen do
  @moduledoc """
  Module for interacting with Alibaba Cloud Model Studio (DashScope) Qwen models.

  DashScope exposes an OpenAI-compatible API. Two billing endpoints are supported:

  - **On-demand** (default): `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`
    with `config :genai, :qwen, api_key:` (`QWEN_API_KEY`, `DASHSCOPE_API_KEY` fallback).
  - **Token plan**: `https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1`
    with `token_api_key:` (`QWEN_TOKEN_KEY`). Enable via `token_plan: true` or
    `mode: :token_plan` in config, `models/1` options, or provider settings.

  Regional on-demand overrides go on `config :genai, :qwen, base_url:`. Token-plan host
  overrides go on `token_plan_base_url:`.
  """
  @base_url "https://dashscope-intl.aliyuncs.com/compatible-mode/v1"
  @token_plan_url "https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1"
  @config_key :qwen
  use GenAI.InferenceProviderBehaviour

  @doc """
  True when token-plan mode is set (`token_plan: true` or `mode: :token_plan`).
  """
  # ⟦𓊈𓏝𓌻𓊧⟧ token_plan? :: True when token-plan mode is set.
  def token_plan?(settings \\ [])

  def token_plan?(settings) do
    settings
    |> normalize_settings()
    |> scopes()
    |> Enum.any?(&token_plan_flag?/1)
  end

  @doc """
  Compatible-mode root URL. Token-plan mode selects the token-plan host; an explicit
  per-request `:base_url` still wins.
  """
  # ⟦𓎯𓍺𓇐𓌑⟧ base_url :: Compatible-mode root URL for the active plan.
  def base_url(settings \\ [])

  def base_url(settings) do
    ctx = normalize_settings(settings)

    cond do
      url = request_get(ctx, :base_url) ->
        url

      token_plan?(ctx) ->
        find_get(ctx, :token_plan_base_url) || @token_plan_url

      true ->
        config_get(ctx, :base_url) || @base_url
    end
  end

  @doc "Bearer token for the active plan (`api_key` on-demand, `token_api_key` on token plan)."
  # ⟦𓏲𓁑𓉉𓂝⟧ api_key :: Bearer token for the active plan.
  def api_key(settings \\ [], options \\ [])

  def api_key(settings, options) do
    ctx = normalize_settings(settings)

    cond do
      key = present(get(options, :api_key)) ->
        key

      key = request_get(ctx, :api_key) ->
        key

      token_plan?(ctx) ->
        find_get(ctx, :token_api_key) ||
          raise GenAI.RequestError,
            message: "API KEY NOT FOUND - #{__MODULE__} (token plan; set QWEN_TOKEN_KEY)"

      true ->
        find_get(ctx, :api_key) ||
          raise GenAI.RequestError, message: "API KEY NOT FOUND - #{__MODULE__}"
    end
  end

  @doc """
  Native Model Studio API root (`/api/v1`) derived from the active compatible-mode URL.

  Used by `catalog/1` — the OpenAI-compatible `/models` list omits video and some audio ids.
  """
  # ⟦𓈀𓋛𓀊𓄪⟧ native_base_url :: Native Model Studio API root derived from compatible-mode base_url.
  def native_base_url(settings \\ [])

  def native_base_url(settings) do
    base = base_url(settings) |> String.trim_trailing("/")

    cond do
      String.ends_with?(base, "/compatible-mode/v1") ->
        String.replace_suffix(base, "/compatible-mode/v1", "/api/v1")

      String.ends_with?(base, "/api/v1") ->
        base

      true ->
        uri = URI.parse(base)
        URI.to_string(%{uri | path: "/api/v1"})
    end
  end

  @doc """
  Retrieves a list of models supported by the DashScope compatible-mode API.
  """
  # ⟦𓏶𓁄𓉙𓃉⟧ models :: Retrieves a list of models supported by the DashScope compatible-mode API.
  def models(settings \\ []) do
    headers = headers(settings)
    call = api_call(:get, "#{base_url(settings)}/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{data: models, object: "list"} <- json do
        {:ok, Enum.map(models, &model_from_json/1)}
      else
        _ -> {:error, {:response, json}}
      end
    end
  end

  @doc """
  Full Model Studio catalog via native `GET /api/v1/models` (paginated).

  Unlike `models/0` (OpenAI-compatible, ~160 chat/image/embed ids), this includes
  video, extra audio, and capability metadata. Options (keyword):

  - `:page_size` — default 100
  - `:language` — default `"en-US"`
  - `:capabilities` — string or list, e.g. `"TR"` or `["TG", "Reasoning"]`
  - `:providers` — string or list, e.g. `"qwen"`
  """
  # ⟦𓆰𓊓𓁲𓆷⟧ catalog :: Full Model Studio catalog via native GET /api/v1/models.
  def catalog(settings \\ []) do
    page_size = settings[:page_size] || 100
    language = settings[:language] || "en-US"

    fetch_catalog_page(settings, 1, page_size, language, [])
  end

  defp fetch_catalog_page(settings, page_no, page_size, language, acc) do
    headers = headers(settings)
    url = catalog_url(page_no, page_size, language, settings)
    call = api_call(:get, url, headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms),
         %{success: true, output: output} <- json do
      models = Enum.map(output[:models] || [], &native_model_from_json/1)
      acc = acc ++ models
      total = output[:total] || length(acc)

      if length(acc) >= total or models == [] do
        {:ok, acc}
      else
        fetch_catalog_page(settings, page_no + 1, page_size, language, acc)
      end
    else
      %{success: false} = json -> {:error, {:response, json}}
      other -> other
    end
  end

  defp catalog_url(page_no, page_size, language, settings) do
    params =
      [
        {"page_no", Integer.to_string(page_no)},
        {"page_size", Integer.to_string(page_size)},
        {"language", language}
      ]
      |> Kernel.++(repeat_param("capabilities", settings[:capabilities]))
      |> Kernel.++(repeat_param("providers", settings[:providers]))
      |> URI.encode_query()

    "#{native_base_url(settings)}/models?#{params}"
  end

  defp repeat_param(_key, nil), do: []
  defp repeat_param(key, value) when is_binary(value), do: [{key, value}]
  defp repeat_param(key, value) when is_atom(value), do: [{key, to_string(value)}]

  defp repeat_param(key, values) when is_list(values) do
    Enum.map(values, &{key, to_string(&1)})
  end

  defp model_from_json(json) do
    %GenAI.Model{
      model: json[:id],
      provider: __MODULE__,
      details: json
    }
  end

  defp native_model_from_json(json) do
    %GenAI.Model{
      model: json[:model],
      provider: __MODULE__,
      details: json
    }
  end

  defp normalize_settings(settings) when is_list(settings) do
    %{
      settings: settings,
      config_settings: Application.get_env(:genai, :qwen, [])
    }
  end

  defp normalize_settings(settings) when is_map(settings) do
    Map.put_new(settings, :config_settings, Application.get_env(:genai, :qwen, []))
  end

  defp normalize_settings(_), do: %{config_settings: Application.get_env(:genai, :qwen, [])}

  defp scopes(ctx) do
    [
      ctx[:model_settings],
      ctx[:provider_settings],
      ctx[:settings],
      ctx[:config_settings]
    ]
  end

  defp token_plan_flag?(src) do
    cond do
      is_nil(src) -> false
      truthy?(get(src, :token_plan)) -> true
      token_mode?(get(src, :mode)) -> true
      token_mode?(get(src, :plan)) -> true
      true -> false
    end
  end

  defp token_mode?(mode) when mode in [:token_plan, "token_plan", :token, "token"], do: true
  defp token_mode?(_), do: false

  defp truthy?(v) when v in [true, true, "true", 1, "1"], do: true
  defp truthy?(_), do: false

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
