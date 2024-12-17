defmodule GenAI.Thread do
  @vsn 1.0
  @moduledoc """
  This module defines the chat struct used to manage conversations with generative AI models.
  """
  require Logger

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
  require Logger
  defp add_vertex(context, node) do
    update_in(context, [Access.key(:flow)], & GenAI.Flow.add_vertex(&1, node))
  end
  defp add_edge(context, link) do
    update_in(context, [Access.key(:flow)], & GenAI.Flow.add_edge(&1, link))
  end

  defp auto_link?(context, options) do
    options[:link] != false and context.flow.last_vertex != nil
  end

  defp append_node(context, node, options \\ nil)
  defp append_node(context, node, options) do
    source_node = context.flow.last_vertex
    cond do
      auto_link?(context, options) == false ->
        context = context
                  |> add_vertex(node)
      is_struct(options[:link]) ->
        context = context
                  |> add_vertex(node)
                  |> add_edge(options.link)
      :else ->
        {:ok, target_node} = GenAI.Flow.NodeProtocol.id(node)
        context = context
                  |> add_vertex(node)
                  |> add_edge(GenAI.Flow.Link.new(source_node, target_node))
    end
  end

  def with_model(context, model) do
    # TODO CONFIRM INPUT ADHERES TO MODEL PROTOCOL
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    node = GenAI.Flow.Node.new(id, model)
    context
    |> append_node(node)
  end

  def with_tool(context, tool) do
    # TODO CONFIRM VALUE ADHERES TO TOOL PROTOCOL
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    node = GenAI.Flow.Node.new(id, tool)
    context
    |> append_node(node)
  end
  def with_tools(context, tools) do
    Enum.reduce(tools, context, fn(tool, context) ->
      with_tool(context, tool)
    end)
    context
  end

  def with_api_key(context, provider, api_key) do
    # TODO CONFIRM VALUE ADHERES TO TOOL PROTOCOL
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    content = %GenAI.Provider.Setting{provider: provider, setting: :api_key, value: api_key}
    node = GenAI.Flow.Node.new(id, content)

    context
    |> append_node(node)
  end

  def with_api_org(context, provider, api_org) do
    # TODO CONFIRM VALUE ADHERES TO TOOL PROTOCOL
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    content = %GenAI.Provider.Setting{provider: provider, setting: :api_org, value: api_org}
    node = GenAI.Flow.Node.new(id, content)

    context
    |> append_node(node)
  end

  def with_setting(context, setting, value) do
    # TODO CONFIRM VALUE ADHERES TO TOOL PROTOCOL
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    content = %GenAI.Setting{setting: :setting, value: value}
    node = GenAI.Flow.Node.new(id, content)
    context
    |> append_node(node)
  end
  def with_setting(context, setting_object) do
    # TODO CONFIRM VALUE ADHERES TO TOOL PROTOCOL
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    node = GenAI.Flow.Node.new(id, setting_object)
    context
    |> append_node(node)
  end
  def with_settings(context, settings) do
    Enum.reduce(settings, context,
      fn
        ({setting, value}, context) -> with_setting(context, setting, value)
        (value, context) when is_struct(value) -> with_setting(context, value)
      end
    )
  end


  def with_safety_setting(context, safety_setting, threshold) do
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    content = %GenAI.Setting{setting: {:__multi__, :safety_setting}, value: %{category: safety_setting, threshold: threshold}}
    node = GenAI.Flow.Node.new(id, content)
    context
    |> append_node(node)
  end
  def with_safety_setting(context, safety_setting_object) do
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    node = GenAI.Flow.Node.new(id, safety_setting_object)
    context
    |> append_node(node)
  end
  def with_safety_settings(context, safety_settings) do
    Enum.reduce(safety_settings, context,
      fn
        ({setting, value}, context) -> with_safety_setting(context, setting, value)
        (value, context) when is_struct(value) -> with_safety_setting(context, value)
      end
    )
  end

  def with_message(context, message,_) do
    # TODO CONFIRM VALUE ADHERES TO TOOL PROTOCOL
    id = GenAI.UUID.new() # todo option to pass in/obtain from model
    node = GenAI.Flow.Node.new(id, message)
    context
    |> append_node(node)
  end

  def with_messages(context, messages, options) do
    Enum.reduce(messages, context, fn(message, context) ->
      with_message(context, message, options)
    end)
  end

  def with_stream_handler(context, handler, options) do
    Logger.info("nyi")
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