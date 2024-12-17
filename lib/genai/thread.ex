defmodule GenAI.Thread do
  @moduledoc """
  This module defines the chat struct used to manage conversations with generative AI models.
  """

  @vsn 1.0

  defstruct [
    state: %GenAI.Thread.State{},
    flow: %GenAI.Flow{},
    vsn: @vsn
  ]
end



defimpl GenAI.ThreadProtocol, for: [GenAI.Thread] do
  @moduledoc """
  This allows chat contexts to be used for configuring and running GenAI interactions.
  """
  #  alias GenAI.Graph.Node
  #  alias GenAI.Graph.ModelNode
  #  alias GenAI.Graph.MessageNode
  #  alias GenAI.Graph.SettingNode
  #  alias GenAI.Graph.ProviderSettingNode
  #  alias GenAI.Graph.ToolNode

  defp append_node(context, node) do
#    context
#    |> update_in([Access.key(:flow)], & GenAI.Graph.append_node(&1, node))
    context
  end

  def with_model(context, model) do
    context
    #|> append_node(%ModelNode{content: model})
  end

  def with_tool(context, tool) do
    context
    #|> append_node(%ToolNode{content: tool})
  end
  def with_tools(context, tools) do
    #Enum.reduce(tools, context, fn(tool, context) ->
    #  with_tool(context, tool)
    #end)
    context
  end

  def with_api_key(context, provider, api_key) do
    context
    #|> append_node(%ProviderSettingNode{provider: provider, setting: :api_key, value: api_key})
  end

  def with_api_org(context, provider, api_org) do
    context
    #|> append_node(%ProviderSettingNode{provider: provider, setting: :api_org, value: api_org})
  end

  def with_setting(context, setting, value) do
    context
    #|> append_node(%SettingNode{setting: setting, value: value})
  end
  def with_setting(context, setting_object) do
    context
    #|> append_node(%SettingNode{setting: setting, value: value})
  end
  def with_settings(context, settings) do
    context
    #|> append_node(%SettingNode{setting: setting, value: value})
  end


  def with_safety_setting(context, safety_setting, threshold) do
    context
    #|> append_node(%SettingNode{setting: {:__multi__, :safety_setting}, value: %{category: safety_setting, threshold: threshold}})
  end
  def with_safety_setting(context, safety_setting_object) do
    context
    #|> append_node(%SettingNode{setting: {:__multi__, :safety_setting}, value: %{category: safety_setting, threshold: threshold}})
  end
  def with_safety_settings(context, safety_settings) do
    context
    #|> append_node(%SettingNode{setting: {:__multi__, :safety_setting}, value: %{category: safety_setting, threshold: threshold}})
  end

  def with_message(context, message,_) do
    context
    #|> append_node(%MessageNode{content: message})
  end

  def with_messages(context, messages, options) do
    context
    #Enum.reduce(messages, context, fn(message, context) ->
    #  with_message(context, message, options)
    #end)
  end

  def with_stream_handler(context, handler, options) do
    context
  end

  def stream(context, options)
  def stream(context, options) do
    {:ok, :pending}
  end

  @doc """
  Runs inference on the chat context.

  This function determines the final settings and model, prepares the messages, and then delegates the actual inference execution to the selected provider's `chat/3` function.
  """
  def run(context, options)
  def run(context, options) do
#    with {:prepare_state, {:ok, state}} <-
#           GenAi.Graph.NodeProtocol.apply(context.graph, context.state)
#           |> label(:prepare_state),
#         {:effective_model, {:ok, model, state}} <-
#           GenAI.Thread.StateProtocol.model(state)
#           |> label(:effective_model) do
#      GenAI.ProviderBehaviour.run(model, state)
#    end
    {:ok, :pending}
  end

  def execute(context, command, options) do
    {:ok, :pending}
  end

  defp label(response, title) do
    {title, response}
  end

end