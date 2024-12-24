defmodule GenAI do

  @doc """
  Creates a new chat context.
  """
  def chat(context_type \\ :default, options \\ nil)
  def chat(:default, options), do: GenAI.Thread.new(options)
  def chat(:standard, options), do: GenAI.Thread.new(options)

  # Delegate function calls to the GenAI.ThreadProtocol implementation for the current context.
  defdelegate with_model(context, model), to: GenAI.ThreadProtocol
  defdelegate with_tool(context, tool), to: GenAI.ThreadProtocol
  defdelegate with_tools(context, tools), to: GenAI.ThreadProtocol
  defdelegate with_api_key(context, provider, api_key), to: GenAI.ThreadProtocol
  defdelegate with_api_org(context, provider, api_org), to: GenAI.ThreadProtocol
  defdelegate with_setting(context, setting, value), to: GenAI.ThreadProtocol
  defdelegate with_setting(context, setting_object), to: GenAI.ThreadProtocol
  defdelegate with_settings(context, settings), to: GenAI.ThreadProtocol
  defdelegate with_safety_setting(context, safety_setting, threshold), to: GenAI.ThreadProtocol
  defdelegate with_safety_settings(context, safety_settings), to: GenAI.ThreadProtocol
  defdelegate with_message(context, message, options \\ nil), to: GenAI.ThreadProtocol
  defdelegate with_messages(context, messages, options \\ nil), to: GenAI.ThreadProtocol
  defdelegate with_stream_handler(context, handler, options \\ nil), to: GenAI.ThreadProtocol

  defdelegate run(context, options \\ nil), to: GenAI.ThreadProtocol
  defdelegate stream(context, options \\ nil), to: GenAI.ThreadProtocol
  defdelegate execute(context, command \\ :thread, options \\ nil), to: GenAI.ThreadProtocol

end
