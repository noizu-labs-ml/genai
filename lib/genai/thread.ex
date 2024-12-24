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

  @default_options [
    auto_head: true,
    auto_link: true
  ]

  def new(options \\ nil)
  def new(options) do
    options = Keyword.merge(@default_options, options || [])
    flow_id = options[:id] || :auto
    flow = GenAI.Flow.new(flow_id, options)

    %__MODULE__{
      state: %GenAI.Thread.State{flow: flow.id},
      flow: flow,
      vsn: @vsn
    }
  end

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
  defp add_node(context, node, options \\ nil) do
    update_in(context, [Access.key(:flow)], & GenAI.Flow.add_node(&1, node, options))
  end
  defp add_link(context, link) do
    update_in(context, [Access.key(:flow)], & GenAI.Flow.add_link(&1, link))
  end

  defp auto_link?(context, options) do
    options[:link] != false and context.flow.last_node != nil
  end

  defp append_node(context, node, options \\ nil)
  defp append_node(context, node, options) do
    context = context
              |> add_node(node, options)
  end

  #-------------------------------------
  # with_model/2
  #-------------------------------------
  def with_model(context, model) do
    if GenAI.ModelProtocol.impl_for(model) do
      {:ok, n} = GenAI.Flow.NodeProtocol.with_id(model)
      context
      |> append_node(n)
    else
      cond do
        is_struct(model) ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.ModelProtocol: #{model.__struct__}"
          :else ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.ModelProtocol: #{inspect model}"
      end
    end
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_tool(context, tool) do
    if GenAI.ToolProtocol.impl_for(tool) do
      {:ok, n} = GenAI.Flow.NodeProtocol.with_id(tool)
      context
      |> append_node(n)
    else
      cond do
        is_struct(tool) ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.ModelProtocol: #{tool.__struct__}"
        :else ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.ModelProtocol: #{inspect tool}"
      end
    end
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_tools(context, tools) do
    Enum.reduce(tools, context, fn(tool, context) ->
      with_tool(context, tool)
    end)
    context
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_api_key(context, provider, api_key) do
    n = %GenAI.Setting.ProviderSetting{
      id: UUID.uuid4(),
      provider: provider,
      setting: :api_key,
      value: api_key
    }
    context
    |> append_node(n)
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_api_org(context, provider, api_org) do
      n = %GenAI.Setting.ProviderSetting{
        id: UUID.uuid4(),
        provider: provider,
        setting: :api_org,
        value: api_org
      }
      context
      |> append_node(n)
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_setting(context, setting, value) do
      n = %GenAI.Setting{
        id: UUID.uuid4(),
        setting: setting,
        value: value
      }
      context
      |> append_node(n)
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_setting(context, setting) do
    if GenAI.SettingProtocol.impl_for(setting) do
      {:ok, n} = GenAI.Flow.NodeProtocol.with_id(setting)
      context
      |> append_node(n)
    else
      cond do
        is_struct(setting) ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.SettingProtocol: #{setting.__struct__}"
        :else ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.SettingProtocol: #{inspect setting}"
      end
    end
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_settings(context, settings) do
    Enum.reduce(settings, context,
      fn
        ({setting, value}, context) -> with_setting(context, setting, value)
        (value, context) when is_struct(value) -> with_setting(context, value)
      end
    )
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_safety_setting(context, category, threshold) do
    n = %GenAI.Setting.SafetySetting{
      id: UUID.uuid4(),
      category: category,
      threshold: threshold
    }
    context
    |> append_node(n)
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_safety_setting(context, safety_setting) do
    if GenAI.SettingProtocol.impl_for(safety_setting) do
      {:ok, n} = GenAI.Flow.NodeProtocol.with_id(safety_setting)
      context
      |> append_node(n)
    else
      cond do
        is_struct(safety_setting) ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.SettingProtocol: #{safety_setting.__struct__}"
        :else ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.SettingProtocol: #{inspect safety_setting}"
      end
    end
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_safety_settings(context, safety_settings) do
    Enum.reduce(safety_settings, context,
      fn
        ({category, threshold}, context) -> with_safety_setting(context, category, threshold)
        (safety_setting, context) when is_struct(safety_setting) -> with_safety_setting(context, safety_setting)
      end
    )
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_message(context, message, options)
  def with_message(context, message, _) do
    if GenAI.MessageProtocol.impl_for(message) do
      {:ok, n} = GenAI.Flow.NodeProtocol.with_id(message)
      context
      |> append_node(n)
    else
      cond do
        is_struct(message) ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.MessageProtocol: #{message.__struct__}"
        :else ->
          raise GenAI.Flow.Exception, "With Model Argument Must Implement GenAI.MessageProtocol: #{inspect message}"
      end
    end
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_messages(context, messages, options)
  def with_messages(context, messages, options) do
    Enum.reduce(messages, context, fn(message, context) ->
      with_message(context, message, options)
    end)
  end

  #-------------------------------------
  #
  #-------------------------------------
  def with_stream_handler(context, handler, options) do
    Logger.info("nyi")
    context
  end

  #-------------------------------------
  #
  #-------------------------------------
  def stream(context, options)
  def stream(context, options) do
    {:ok, :pending}
  end

  #-------------------------------------
  #
  #-------------------------------------
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

  #-------------------------------------
  #
  #-------------------------------------
  def execute(context, command, options) do
    {:ok, :pending}
  end

  #-------------------------------------
  #
  #-------------------------------------
  defp label(response, title) do
    {title, response}
  end

end