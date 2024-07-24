defmodule GenAI.Thread.State do
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
    Add multiple setting selectors/constraints
    """
    def with_settings(state, settings)
    def with_settings(state, settings) when is_list(settings) do
      settings
      |> Enum.reduce_while({:ok, state},
           fn
             {setting, value}, {:ok, state} -> {:cont, GenAI.Thread.StateProtocol.with_setting(state, setting, value)}
             _, error -> {:halt, error}
           end
         )
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
    Add a provider specific settings selector/constraint
    """
    def with_provider_settings(state, provider, settings)
    def with_provider_settings(state, provider, settings) when is_list(settings) do
      settings
      |> Enum.reduce_while({:ok, state},
           fn
             {setting, value}, {:ok, state} -> {:cont, GenAI.Thread.StateProtocol.with_provider_setting(state, provider, setting, value)}
             _, error -> {:halt, error}
           end
         )
    end


    @doc """
    Add a model specific setting selector/constraint
    """
    def with_model_setting(state, model, setting, value)
    def with_model_setting(state, model, setting, value) do
      with {:ok, m} <- GenAI.ModelProtocol.model(model),
           {:ok, p} <- GenAI.ModelProtocol.provider(model) do
        key = {p, m}
        state
        |> update_in(
             [Access.key(:model_settings), key],
             fn
               nil -> %{setting => [value]}
               x -> update_in(x, [setting], & [value | (&1 || []) ])
             end
           )
        |> ok()
      end
    end

    @doc """
    Add a model specific setting selector/constraint
    """
    def with_model_settings(state, model, settings)
    def with_model_settings(state, model, settings) when is_list(settings) do
      settings
      |> Enum.reduce_while({:ok, state},
           fn
             {setting, value}, {:ok, state} -> {:cont, GenAI.Thread.StateProtocol.with_model_setting(state, model, setting, value)}
             _, error -> {:halt, error}
           end
         )
    end


    @doc """
    Add a tool
    """
    def with_tool(state, tool)
    def with_tool(state, tool) do
      with {:ok, name} <- GenAI.ToolProtocol.name(tool) do
        state
        |> update_in([Access.key(:tools), name], & [tool | (&1 || []) ])
        |> ok()
      end
    end


    @doc """
    Add a tools
    """
    def with_tools(state, tools)
    def with_tools(state, nil), do: {:ok, state}
    def with_tools(state, tools) when is_list(tools) do
      tools
      |> Enum.reduce_while({:ok, state},
           fn
             tool, {:ok, state} -> {:cont, GenAI.Thread.StateProtocol.with_tool(state, tool)}
             _, error -> {:halt, error}
           end
         )
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
           [Access.key(:messages)], & Enum.reverse(messages) ++ (&1 || [])
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
          {{:__multi__, k}, v} ->
            Enum.map(v, & {k, &1})
          {k, [v|_]} -> {k, v}
        end
      )
      |> List.flatten()
      |> effective_value_fetch_success(state)
    end

    def model_settings(state, model) do
      with {:ok, m} <- GenAI.ModelProtocol.model(model),
           {:ok, p} <- GenAI.ModelProtocol.provider(model) do
        key = {p, m}
        with settings = %{} <- state.model_settings[key] do
          Enum.map(settings,
            fn
              {{:__multi__, k}, v} -> {k, v}
              {k, [v|_]} -> {k, v}
            end
          )
          |> effective_value_fetch_success(state)
        else
          _ ->
            effective_value_fetch_success([], state)
        end
      end
    end


    @doc """
    Obtain the effective provider settings as of current state.
    @note temporary logic - pending support for context specific dynamic selection
    """
    def provider_settings(state, provider) do
      with settings = %{} <- state.provider_settings[provider] do
        Enum.map(settings,
          fn
            {{:__multi__, k}, v} -> {k, v}
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
           # Temp logic take top
            {_,[tool|_]}, state ->
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
