defmodule GenAI do

  defmacro loop(context, name, iterator, options \\ nil, do: chain) do
        # todo use a process dict hack to track entry/outro so we can repopulate context correctly.
        # rather than passing the |> pip which may break
        # or at least modify so context var is injected and inside of loop user may use context |> logic
        tag = {:loop_start, name}
      quote do
         with {:ok, {context, {enter_loop, exit_loop}}} <- GenAIProtocol.loop(unquote(context), unquote(name), unquote(iterator), unquote(options)) do
           context
           |> GenAIProtocol.enter_loop(enter_loop)
           |> unquote(chain)
           |> GenAIProtocol.exit_loop(exit_loop)
         end
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
  def thread() do
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

  defdelegate tag(context, tag, options \\ nil), to: GenAIProtocol

end
