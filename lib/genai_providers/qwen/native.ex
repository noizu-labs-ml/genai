defmodule GenAI.Provider.Qwen.Native do
  @moduledoc "Native DashScope generation provider using Qwen credentials and an explicit native_base_url."
  use GenAI.InferenceProviderBehaviour, config_key: :qwen

  def do_run(session, context, options) do
    case GenAI.InferenceProvider.DefaultProvider.do_run(
           __MODULE__,
           session,
           context,
           options || []
         ) do
      {:ok, {%GenAI.ChatCompletion{}, _}} = ok -> ok
      {:ok, %Finch.Response{status: status}} -> {:error, {:dashscope_http_error, status}}
      {:error, %Finch.Response{status: status}} -> {:error, {:dashscope_http_error, status}}
      {:error, reason} when is_atom(reason) -> {:error, reason}
      _ -> {:error, :dashscope_request_failed}
    end
  end

  def do_stream(session, context, options) do
    options = Keyword.put(options || [], :stream, true)

    with {:ok, {model, session}} <-
           GenAI.ThreadProtocol.effective_model(session, context, options),
         {:ok, encoder} <- GenAI.ModelProtocol.encoder(model),
         {:ok, {effective, session}} <- effective_settings(model, session, context, options),
         {:ok, {tools, session}} <-
           GenAI.ThreadProtocol.effective_tools(session, model, context, options),
         {:ok, {messages, session}} <-
           GenAI.ThreadProtocol.effective_messages(session, model, context, options),
         {:ok, {body, session}} <-
           encoder.request_body(model, messages, tools, effective, session, context, options),
         {:ok, {headers, session}} <- encoder.headers(model, effective, session, context, options),
         {:ok, {{method, url}, session}} <-
           encoder.endpoint(model, effective, session, context, options),
         handler_options =
           options
           |> Keyword.put(:native_stream_handler, effective[:settings][:stream_handler])
           |> Keyword.put(:stream_model, model.model)
           |> Keyword.put(:stream_provider, model.provider),
         {:ok, {handler, session}} <-
           GenAI.Provider.Qwen.Native.StreamHandler.begin_stream(
             nil,
             session,
             context,
             handler_options
           ),
         {:ok, state} <-
           GenAI.InferenceProvider.Helpers.stream_api_call(
             handler,
             method,
             url,
             headers,
             body,
             options[:finch]
           ),
         {:ok, acc} <- GenAI.Provider.Qwen.Native.StreamHandler.finish(state) do
      {:ok, {acc, session}}
    else
      {:error, reason} when is_atom(reason) ->
        {:error, reason}

      {:error, {tag, status}}
      when tag in [:dashscope_stream_error, :dashscope_http_error] and is_integer(status) ->
        {:error, {tag, status}}

      _ ->
        {:error, :dashscope_stream_failed}
    end
  end
end
