defmodule GenAI do

  defmacro loop(context, name, iterator, options \\ nil, do: chain) do
        # todo use a process dict hack to track entry/outro so we can repopulate context correctly.
        # rather than passing the |> pip which may break
        tag = {:loop_start, name}
      quote do
          unquote(context)
          |> GenAI.tag(unquote(tag))
          |> unquote(chain)
          |> GenAI.loop(name, iterator, options)
        end
  end

  @doc """
  Creates a new chat context.
  """
  def chat() do
    %GenAI.Chat{}
  end
  def chat(:new) do
    %GenAI.ChatNew{}
  end

  # Delegate function calls to the GenAIProtocol implementation for the current context.
  defdelegate with_model(context, model, options \\ nil), to: GenAIProtocol
  defdelegate with_tool(context, tool, options \\ nil), to: GenAIProtocol
  defdelegate with_tools(context, tools, options \\ nil), to: GenAIProtocol
  defdelegate with_api_key(context, provider, api_key, options \\ nil), to: GenAIProtocol
  defdelegate with_api_org(context, provider, api_org, options \\ nil), to: GenAIProtocol
  defdelegate with_setting(context, setting, value, options \\ nil), to: GenAIProtocol
  defdelegate with_safety_setting(context, safety_setting, threshold, options \\ nil), to: GenAIProtocol
  defdelegate with_message(context, message, options \\ nil), to: GenAIProtocol
  defdelegate with_messages(context, messages, options \\ nil), to: GenAIProtocol
  defdelegate stream(context, handler, options \\ nil), to: GenAIProtocol
  defdelegate run(context, options \\ nil), to: GenAIProtocol
  defdelegate tune_prompt(context, handle, options \\ nil), to: GenAIProtocol
  defdelegate score(context, scorer \\ nil, options \\ nil) , to: GenAIProtocol
  defdelegate fitness(context, fitness, options \\ nil), to: GenAIProtocol
  defdelegate early_stopping(context, sentinel, options \\ nil), to: GenAIProtocol
  defdelegate execute(context, type, options \\ nil), to: GenAIProtocol



end
