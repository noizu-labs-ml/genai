defmodule GenAI.Provider.Qwen.Video do
  @moduledoc """
  Wan 2.7 / HappyHorse video via DashScope async video-synthesis.

  Submits `X-DashScope-Async: enable`, polls `/api/v1/tasks/{id}`, downloads the
  video URL. Declared sync from the caller's perspective (blocks until bytes).
  """
  @config_key :qwen_video
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H
  alias GenAI.Provider.Qwen.DashScope

  @poll_ms 10_000
  @max_polls 60

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities, do: [%{input: [:text], output: :video, mode: :sync}]

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: :video} = req, _options) do
    with {:ok, key} <- DashScope.require_key(req) do
      duration = req.settings[:duration] || req.settings[:duration_seconds] || 5

      body = %{
        model: req.model || "wan2.7-t2v",
        input:
          %{prompt: H.prompt_text(req.prompt)}
          |> maybe(:negative_prompt, req.settings[:negative_prompt]),
        parameters: %{
          resolution: to_string(req.settings[:resolution] || "720P"),
          ratio: to_string(req.settings[:aspect_ratio] || req.settings[:ratio] || "16:9"),
          duration: duration,
          prompt_extend: true
        }
      }

      headers = [{"X-DashScope-Async", "enable"}]

      case H.post_json(DashScope.video_url(req), key, body,
             headers: headers,
             receive_timeout: 60_000
           ) do
        {:ok, %Finch.Response{status: status, body: resp}} when status in 200..299 ->
          with {:ok, task_id} <- task_id(resp) do
            poll(req, key, task_id, 0)
          end

        {:ok, %Finch.Response{status: status, body: resp}} ->
          {:error, {:http_error, status, resp}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}

  defp poll(_req, _key, _task_id, n) when n >= @max_polls, do: {:error, :timeout}

  defp poll(req, key, task_id, n) do
    Process.sleep(@poll_ms)
    url = DashScope.task_url(req, task_id)
    headers = [{"authorization", "Bearer #{key}"}]

    case H.get(url, headers, receive_timeout: 30_000) do
      {:ok, %Finch.Response{status: status, body: resp}} when status in 200..299 ->
        with {:ok, json} <- Jason.decode(resp) do
          case get_in(json, ["output", "task_status"]) do
            "SUCCEEDED" ->
              with {:ok, video_url} <- video_url(json),
                   {:ok, bytes} <- H.download(video_url) do
                {:ok,
                 %{data: bytes, mime: "video/mp4", meta: %{url: video_url, task_id: task_id}}}
              end

            st when st in ["FAILED", "CANCELED", "UNKNOWN"] ->
              {:error, {:task_failed, st}}

            _ ->
              poll(req, key, task_id, n + 1)
          end
        end

      _ ->
        poll(req, key, task_id, n + 1)
    end
  end

  defp task_id(resp) do
    with {:ok, json} <- Jason.decode(resp),
         id when is_binary(id) <- get_in(json, ["output", "task_id"]) do
      {:ok, id}
    else
      _ -> {:error, :unexpected_response}
    end
  end

  defp video_url(json) do
    url =
      get_in(json, ["output", "video_url"]) ||
        get_in(json, ["output", "results", Access.at(0), "url"])

    if is_binary(url), do: {:ok, url}, else: {:error, :unexpected_response}
  end

  defp maybe(map, _k, nil), do: map
  defp maybe(map, k, v), do: Map.put(map, k, v)
end
