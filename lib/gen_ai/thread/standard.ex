defmodule GenAI.ProviderBehaviour do
  @callback run(state :: any) :: {:ok, completion :: any, state :: any} | {:error, term}
  @callback format_tool(tool :: any, state  :: any) :: {:ok, tool :: any, state :: any} | {:error, term}
  @callback format_message(message :: any, state  :: any) :: {:ok, message :: any, state :: any} | {:error, term}

  def run(%{provider: handler}, state), do: run(handler, state)
  def run(handler, state), do: apply(handler, :run, [state])

  def format_tool(%{provider: handler}, tool, state), do: format_tool(handler, tool, state)
  def format_tool(handler, tool, state), do: apply(handler, :format_tool, [tool, state])

  def format_message(%{provider: handler}, message, state), do: format_message(handler, message, state)
  def format_message(handler, message, state), do: apply(handler, :format_message, [message, state])
end

defprotocol GenAI.Thread.StateProtocol do
  def with_model(state, model)
  def with_setting(state, setting, value)
  def with_provider_setting(state, provider, setting, value)
  def with_tool(state, tool)
  def with_message(state, message)
  def with_messages(state, messages)

  def model(state)
  def settings(state)
  def provider_settings(state, provider)
  def messages(state, provider)
  def tools(state, provider)
end

defprotocol GenAI.ModelProtocol do
  def provider(model)
  def model(model)
end

defmodule GenAI.Thread.State do
  alias GenAI.Thread.StateBehaviour
  @behaviour StateBehaviour
  @vsn 1.0
  defstruct [
    model: [],
    settings: %{},
    tools: %{},
    model_settings: %{},
    provider_settings: %{},
    messages: [],
    vsn: @vsn
  ]

  defimpl GenAI.Thread.StateProtocol do
    defp ok(response), do: {:ok, response}
    defp effective_value_fetch_success(response, updated_state), do: {:ok, response, updated_state}

    @doc """
    Add a model selector/constraint
    """
    def with_model(state, model)
    def with_model(state, model) do
      state
      |> update_in([Access.key(:model)], & [model | (&1 || []) ])
      |> ok()
    end

    @doc """
    Add a setting selector/constraint
    """
    def with_setting(state, setting, value)
    def with_setting(state, setting, value) do
      state
      |> update_in([Access.key(:settings), setting], & [value | (&1 || []) ])
      |> ok()
    end

    @doc """
    Add a provider specific setting selector/constraint
    """
    def with_provider_setting(state, provider, setting, value)
    def with_provider_setting(state, provider, setting, value) do
      state
      |> update_in(
           [Access.key(:provider_settings), provider],
           fn
             nil -> %{setting => [value]}
             x -> update_in(x, [setting], & [value | (&1 || []) ])
           end
         )
      |> ok()
    end

    @doc """
    Add a model specific setting selector/constraint
    """
    def with_model_setting(state, model, setting, value)
    def with_model_setting(state, %{model: model}, setting, value) do
      state
      |> update_in(
           [Access.key(:model_settings), model],
           fn
             nil -> %{setting => [value]}
             x -> update_in(x, [setting], & [value | (&1 || []) ])
           end
         )
      |> ok()
    end

    @doc """
    Add a tool
    """
    def with_tool(state, tool)
    def with_tool(state, %{name: name} = tool) do
      state
      |> update_in(
           [Access.key(:tools), name], & [tool | (&1 || []) ]
         )
      |> ok()
    end

    @doc """
    Add message
    """
    def with_message(state, message)
    def with_message(state, message) do
      state
      |> update_in(
           [Access.key(:messages)], & [message | (&1 || []) ]
         )
      |> ok()
    end

    @doc """
    Add messages
    """
    def with_messages(state, messages)
    def with_messages(state, messages) when is_list(messages) do
      state
      |> update_in(
           [Access.key(:messages)], & [Enum.reverse(messages) | (&1 || []) ]
         )
      |> ok()
    end

    @doc """
    Obtain the effective model as of current state.
    @note temporary logic - pending support for context specific dynamic selection
    """
    def model(state) do
      with %{model: [effective_model|_]} <- state do
        effective_value_fetch_success(effective_model, state)
      else
        _ -> {:error, :not_set}
      end
    end

    @doc """
    Obtain the effective settings as of current state.
    @note temporary logic - pending support for context specific dynamic selection
    """
    def settings(state) do
      Enum.map(state.settings,
        fn
          {k, [v|_]} -> {k, v}
        end
      )
      |> effective_value_fetch_success(state)
    end

    @doc """
    Obtain the effective provider settings as of current state.
    @note temporary logic - pending support for context specific dynamic selection
    """
    def provider_settings(state, provider) do
      with settings = %{} <- state.provider_settings[provider] do
        Enum.map(settings,
          fn
            {k, [v|_]} -> {k, v}
          end
        )
        |> effective_value_fetch_success(state)
      else
        _ ->
          effective_value_fetch_success([], state)
      end
    end

    def messages(state, provider) do
      unless state.messages == [] do
        {messages, state} =
          state.messages
          |> Enum.reverse()
          |> Enum.map_reduce(state,
          fn
            message, state ->
              case GenAI.ProviderBehaviour.format_message(provider, message, state) do
                {:ok, message, state} -> {message, state}
                error = {:error, _} -> {error, state}
              end
          end
        )
        errors = Enum.filter(messages,
          fn
            {:error, _} -> true
            _ -> false
          end)
        if errors == [] do
          messages |> effective_value_fetch_success(state)
        else
          {:error, {:format_messages, errors}}
        end
      else
        {:ok, [], state}
      end
    end

    def tools(state, provider) do
      unless state.tools == %{} do
        {tools, state} = Enum.map_reduce(state.tools, state,
          fn
            {_,tool}, state ->
              case GenAI.ProviderBehaviour.format_tool(provider, tool, state) do
                {:ok, tool, state} -> {tool, state}
                error = {:error, _} -> {error, state}
              end
          end
        )
        errors = Enum.filter(tools,
          fn
            {:error, _} -> true
            _ -> false
          end)
        if errors == [] do
          tools |> effective_value_fetch_success(state)
        else
          {:error, {:format_tools, errors}}
        end
      else
        {:ok, nil, state}
      end
    end
  end
end


defprotocol GenAi.Graph.NodeProtocol do
  def apply(node, state)
end

defmodule GenAI.Graph.Node do
  @vsn 1.0
  defstruct [
    identifier: nil,
    content: nil,
    vsn: @vsn
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      {:ok, state}
    end
  end
end

defmodule GenAI.Graph.ModelNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    content: nil,
    vsn: @vsn
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_model(state, node.content)
    end
  end
end


defmodule GenAI.Graph.ToolNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    content: nil,
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_tool(state, node.content)
    end
  end
end

defmodule GenAI.Graph.MessageNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    content: nil,
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_message(state, node.content)
    end
  end
end

defmodule GenAI.Graph.ProviderSettingNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    provider: nil,
    setting: nil,
    value: nil,
    vsn: @vsn
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_provider_setting(state, node.provider, node.setting, node.value)
    end
  end

end

defmodule GenAI.Graph.SettingNode do
  @vsn 1.0
  defstruct [
    identifier: nil,
    setting: nil,
    value: nil,
    vsn: @vsn
  ]

  defimpl GenAi.Graph.NodeProtocol do
    def apply(node, state)
    def apply(node, state) do
      GenAI.Thread.StateProtocol.with_setting(state, node.setting, node.value)
    end
  end
end

defmodule GenAI.Graph do
  @vsn 1.0
  defstruct [
    nodes: [],
    vsn: @vsn
  ]
  def append_node(this, node) do
    %{this | nodes: this.nodes ++ [node]}
  end

  defimpl  GenAi.Graph.NodeProtocol do
    def apply(this, state) do
      Enum.reduce(this.nodes, {:ok, state},
        fn
          node, state = {:error, _} -> state
          node, {:ok, state} ->
            GenAi.Graph.NodeProtocol.apply(node, state)
        end
      )
    end
  end
end




defmodule GenAI.Thread.Standard do
  @moduledoc """
  This module defines the chat struct used to manage conversations with generative AI models.
  """

  @vsn 1.0

  defstruct [
    state: %GenAI.Thread.State{},
    graph: %GenAI.Graph{},
    vsn: @vsn
  ]


  defimpl GenAI.ThreadProtocol do
    @moduledoc """
    Implements the `GenAI.ThreadProtocol` for `GenAI.Thread.Legacy`.

    This allows chat contexts to be used for configuring and running GenAI interactions.
    """
    alias GenAI.Graph.Node
    alias GenAI.Graph.ModelNode
    alias GenAI.Graph.MessageNode
    alias GenAI.Graph.SettingNode
    alias GenAI.Graph.ProviderSettingNode
    alias GenAI.Graph.ToolNode

    defp append_node(context, node) do
      context
      |> update_in([Access.key(:graph)], & GenAI.Graph.append_node(&1, node))
    end

    def with_model(context, model) do
      context
      |> append_node(%ModelNode{content: model})
    end


    def with_tool(context, tool) do
      context
      |> append_node(%ToolNode{content: tool})
    end
    def with_tools(context, tools) do
      Map.reduce(tools, context, fn(tool, context) ->
        with_tool(context, tool)
      end)
    end

    def with_api_key(context, provider, api_key) do
      context
      |> append_node(%ProviderSettingNode{provider: provider, setting: :api_key, value: api_key})
    end

    def with_api_org(context, provider, api_org) do
      context
      |> append_node(%ProviderSettingNode{provider: provider, setting: :api_org, value: api_org})
    end

    def with_setting(context, setting, value) do
      context
      |> append_node(%SettingNode{setting: setting, value: value})
    end

    def with_safety_setting(context, safety_setting, threshold) do
      context
      |> append_node(%SettingNode{setting: :safety_setting, value: %{category: safety_setting, threshold: threshold}})
    end


    def with_message(context, message,_) do
      context
      |> append_node(%MessageNode{content: message})
    end

    def with_messages(context, messages, options) do
      Map.reduce(messages, context, fn(message, context) ->
        with_message(context, message, options)
      end)
    end

    def stream(_context, _handler) do
      {:ok, :nyi}
    end

    @doc """
    Runs inference on the chat context.

    This function determines the final settings and model, prepares the messages, and then delegates the actual inference execution to the selected provider's `chat/3` function.
    """
    def run(context) do
      with {:prepare_state, {:ok, state}} <-
             GenAi.Graph.NodeProtocol.apply(context.graph, context.state)
             |> label(:prepare_state),
           {:effective_model, {:ok, model, state}} <-
             GenAI.Thread.StateProtocol.model(state)
             |> label(:effective_model) do
        GenAI.ProviderBehaviour.run(model, state)
      end
    end

    defp label(response, title) do
      {title, response}
    end

  end
end
