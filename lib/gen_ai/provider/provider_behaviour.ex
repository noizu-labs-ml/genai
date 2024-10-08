defmodule GenAI.ProviderBehaviour do
  @callback run(state :: any) :: {:ok, completion :: any, state :: any} | {:error, term}
  @callback chat(model :: any, messages :: any, tools :: any, hyper_parameters :: any, provider_settings :: any) :: any
  @callback format_tool(tool :: any, state  :: any) :: {:ok, tool :: any, state :: any} | {:error, term}
  @callback format_message(message :: any, state  :: any) :: {:ok, message :: any, state :: any} | {:error, term}



  def run(%{provider: handler}, state), do: run(handler, state)
  def run(handler, state), do: apply(handler, :run, [state])

  def format_tool(%{provider: handler}, tool, state), do: format_tool(handler, tool, state)
  def format_tool(handler, tool, state), do: apply(handler, :format_tool, [tool, state])

  def format_message(%{provider: handler}, message, state), do: format_message(handler, message, state)
  def format_message(handler, message, state), do: apply(handler, :format_message, [message, state])


end

defmodule GenAI.Provider.ModelsBehaviour do
  @callback load_metadata(options :: any) :: term

  def load_metadata(%{provider: handler}, options), do: load_metadata(handler, options)
  def load_metadata(handler, options), do: apply(handler, :load_metadata, [options])
end
