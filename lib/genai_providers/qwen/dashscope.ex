defmodule GenAI.Provider.Qwen.DashScope do
  @moduledoc false
  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H

  @intl "https://dashscope-intl.aliyuncs.com"
  @cn "https://dashscope.aliyuncs.com"
  @token_plan "https://token-plan.ap-southeast-1.maas.aliyuncs.com"

  def api_root(%Request{settings: settings}) do
    case settings[:plan] || settings[:region] || settings[:token_plan] do
      v when v in [:token_plan, "token_plan", :token, "token", true] -> @token_plan
      v when v in [:cn, "cn", :beijing, "beijing"] -> @cn
      _ -> @intl
    end
  end

  def require_key(%Request{} = req) do
    envs =
      case req.settings[:plan] || req.settings[:token_plan] do
        v when v in [:token_plan, "token_plan", :token, "token", true] ->
          ["QWEN_TOKEN_KEY", "DASHSCOPE_API_KEY"]

        _ ->
          ["DASHSCOPE_API_KEY", "QWEN_API_KEY", "QWEN_TOKEN_KEY"]
      end

    Enum.reduce_while(envs, {:error, :missing_api_key}, fn env, _acc ->
      case H.require_key(req, env) do
        {:ok, _} = ok -> {:halt, ok}
        err -> {:cont, err}
      end
    end)
  end

  def multimodal_url(req),
    do: api_root(req) <> "/api/v1/services/aigc/multimodal-generation/generation"

  def video_url(req),
    do: api_root(req) <> "/api/v1/services/aigc/video-generation/video-synthesis"

  def task_url(req, id), do: api_root(req) <> "/api/v1/tasks/#{id}"
end
