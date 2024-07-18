defmodule GenAI do

  @doc """
  Creates a new chat context.
  """
  def chat() do
    %GenAI.Chat{}
  end

  # Delegate function calls to the GenAIProtocol implementation for the current context.
  defdelegate with_model(context, model), to: GenAIProtocol
  defdelegate with_tool(context, tool), to: GenAIProtocol
  defdelegate with_tools(context, tools), to: GenAIProtocol
  defdelegate with_api_key(context, provider, api_key), to: GenAIProtocol
  defdelegate with_api_org(context, provider, api_org), to: GenAIProtocol
  defdelegate with_setting(context, setting, value), to: GenAIProtocol
  defdelegate with_safety_setting(context, safety_setting, threshold), to: GenAIProtocol
  defdelegate with_message(context, message, options \\ nil), to: GenAIProtocol
  defdelegate with_messages(context, messages, options \\ nil), to: GenAIProtocol
  defdelegate stream(context, handler), to: GenAIProtocol
  defdelegate run(context), to: GenAIProtocol






end
