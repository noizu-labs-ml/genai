defmodule GenAI.Provider.Qwen.Native.Encoder do
  @moduledoc "Native DashScope generation format. Select explicitly with Qwen.Models.native/2."
  use GenAI.Model.EncoderBehaviour
  alias GenAI.Provider.Qwen.Native.Messages

  def stream_decoder, do: GenAI.Provider.Qwen.Native.StreamDecoder

  def setting(settings, options, key, default \\ nil) do
    [
      options,
      settings[:model_settings],
      settings[:provider_settings],
      settings[:settings],
      settings[:config_settings]
    ]
    |> Enum.find_value(default, fn scope ->
      if scope && !is_nil(scope[key]), do: {:value, scope[key]}
    end)
    |> then(fn
      {:value, value} -> value
      value -> value
    end)
  end

  def endpoint(model, settings, session, _, options) do
    with {:ok, root} <- native_root(setting(settings, options, :native_base_url)),
         {:ok, api} <- api(model, settings, options) do
      {:ok, {{:post, root <> "/services/aigc/#{api}-generation/generation"}, session}}
    end
  end

  def native_root(nil), do: {:error, :missing_native_base_url}

  def native_root(url) when is_binary(url) do
    uri = URI.parse(String.trim_trailing(url, "/"))

    cond do
      uri.scheme not in ["https", "http"] || is_nil(uri.host) || uri.userinfo || uri.query ||
          uri.fragment ->
        {:error, :invalid_native_base_url}

      uri.path in [nil, "", "/"] ->
        {:ok, URI.to_string(%{uri | path: "/api/v1"})}

      uri.path == "/api/v1" ->
        {:ok, URI.to_string(uri)}

      true ->
        {:error, :invalid_native_base_url}
    end
  end

  def native_root(_), do: {:error, :invalid_native_base_url}

  def headers(_, settings, session, _, options) do
    if GenAI.Provider.Qwen.token_plan?(settings) do
      {:error, :native_token_plan_not_supported}
    else
      key =
        setting(settings, options, :api_key) || System.get_env("DASHSCOPE_API_KEY") ||
          System.get_env("QWEN_API_KEY")

      if is_binary(key) && key != "" do
        headers = [{"authorization", "Bearer " <> key}, {"content-type", "application/json"}]

        headers =
          if setting(settings, options, :stream, false),
            do: [{"X-DashScope-SSE", "enable"} | headers],
            else: headers

        {:ok, {headers, session}}
      else
        {:error, :missing_api_key}
      end
    end
  end

  def encode_message(message, _, session, _, _) do
    with {:ok, encoded} <- Messages.encode(message), do: {:ok, {encoded, session}}
  end

  def encode_tool(%GenAI.Tool{} = tool, _, session, _, _) do
    {:ok,
     {%{
        type: "function",
        function: %{name: tool.name, description: tool.description, parameters: tool.parameters}
      }, session}}
  end

  def encode_tool(_, _, _, _, _), do: {:error, :unsupported_native_tool}

  @parameters [
    :temperature,
    :top_p,
    :top_k,
    :max_tokens,
    :max_completion_tokens,
    :preserve_thinking,
    :seed,
    :repetition_penalty,
    :presence_penalty,
    :frequency_penalty,
    :response_format,
    :enable_thinking,
    :thinking_budget,
    :reasoning_effort,
    :parallel_tool_calls,
    :tool_choice,
    :tool_stream,
    :logprobs,
    :top_logprobs,
    :vl_high_resolution_images
  ]

  def request_body(model, messages, tools, settings, session, _, options) do
    with {:ok, name} <- GenAI.ModelProtocol.name(model),
         {:ok, api} <- api(model, settings, options),
         {:ok, messages} <-
           Messages.for_api(messages, api, setting(settings, options, :preserve_thinking, true)) do
      params =
        Enum.reduce(@parameters, %{result_format: "message"}, fn key, acc ->
          case setting(settings, options, key) do
            nil -> acc
            value -> Map.put(acc, key, value)
          end
        end)

      params =
        case setting(settings, options, :stop_sequence, setting(settings, options, :stop)) do
          nil -> params
          stop -> Map.put(params, :stop, stop)
        end

      params = if tools in [[], nil], do: params, else: Map.put(params, :tools, tools)

      params =
        if setting(settings, options, :stream, false),
          do: Map.put(params, :incremental_output, true),
          else: params

      {:ok, {%{model: name, input: %{messages: messages}, parameters: params}, session}}
    end
  end

  def completion_response(json, model, _, _, _, _) do
    GenAI.Provider.Qwen.Native.Response.completion(json, model)
  end

  defp api(model, settings, options) do
    case setting(settings, options, :native_api, (model.details || %{})[:native_api] || :text) do
      mode when mode in [:text, "text"] -> {:ok, "text"}
      mode when mode in [:multimodal, "multimodal"] -> {:ok, "multimodal"}
      _ -> {:error, :unsupported_native_api}
    end
  end
end
