defmodule GenAI.Provider.Qwen do
  @moduledoc """
  Module for interacting with Alibaba Cloud Model Studio (DashScope) Qwen models.

  DashScope exposes an OpenAI-compatible API. The default international endpoint is
  `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`. Auth is a Bearer token from
  `config :genai, :qwen, api_key:` (`QWEN_API_KEY`, with `DASHSCOPE_API_KEY` as a
  fallback in this library's test/dev config).

  Regional overrides go on `config :genai, :qwen, base_url:` — for example the Beijing
  console uses `https://dashscope.aliyuncs.com/compatible-mode/v1`.
  """
  @base_url "https://dashscope-intl.aliyuncs.com/compatible-mode/v1"
  @config_key :qwen
  use GenAI.InferenceProviderBehaviour

  @doc "Runtime base_url from `config :genai, :qwen, base_url:` (DashScope compatible-mode /v1)."
  # ⟦𓎯𓍺𓇐𓌑⟧ base_url :: Runtime base_url from `config :genai, :qwen, base_url:`.
  def base_url, do: GenAI.Provider.MediaHelpers.base_url(:qwen, @base_url)

  @doc """
  Native Model Studio API root (`/api/v1`) derived from compatible-mode `base_url/0`.

  Used by `catalog/1` — the OpenAI-compatible `/models` list omits video and some audio ids.
  """
  # ⟦𓈀𓋛𓀊𓄪⟧ native_base_url :: Native Model Studio API root derived from compatible-mode base_url.
  def native_base_url do
    base = base_url() |> String.trim_trailing("/")

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
    call = api_call(:get, "#{base_url()}/models", headers)

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

    "#{native_base_url()}/models?#{params}"
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
end
