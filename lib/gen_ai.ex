defmodule GenAI do

  @doc """
  Creates a new chat context.
  """
  def chat(thread_provider \\ :default)
  def chat(:default), do: %GenAI.Thread.Legacy{}
  def chat(:vnext), do: %GenAI.Thread.Legacy{}


  # Delegate function calls to the GenAI.ThreadProtocol implementation for the current context.
  defdelegate with_model(context, model), to: GenAI.ThreadProtocol
  defdelegate with_tool(context, tool), to: GenAI.ThreadProtocol
  defdelegate with_tools(context, tools), to: GenAI.ThreadProtocol
  defdelegate with_api_key(context, provider, api_key), to: GenAI.ThreadProtocol
  defdelegate with_api_org(context, provider, api_org), to: GenAI.ThreadProtocol
  defdelegate with_setting(context, setting, value), to: GenAI.ThreadProtocol
  defdelegate with_safety_setting(context, safety_setting, threshold), to: GenAI.ThreadProtocol
  defdelegate with_message(context, message, options \\ nil), to: GenAI.ThreadProtocol
  defdelegate with_messages(context, messages, options \\ nil), to: GenAI.ThreadProtocol
  defdelegate stream(context, handler), to: GenAI.ThreadProtocol
  defdelegate run(context), to: GenAI.ThreadProtocol






end
