defmodule GenAI.Settings do
  @moduledoc """
  This module defines the settings struct used to configure GenAI interactions.
  """

  @vsn 1.0

  defstruct [
    model: [],
    api_key: %{},
    api_org: %{},
    hyper_params: [],
    tools: [],
    vsn: @vsn
  ]


  defimpl GenAIProtocol do
    @moduledoc """
    Implements the `GenAIProtocol` for `GenAI.Settings`.

    This allows settings to be used as a context for configuring GenAI interactions.
    """
    def with_model(context, model) do
      %{context | model: [model | context.model]}
    end

    def with_tool(context, tool) do
      %{context | tools: [tool | context.tools]}
    end
    def with_tools(context, tools) do
      %{context | tools: tools ++ context.tools}
    end

    def with_api_key(context, provider, api_key) do
      %{context | api_key: Map.put(context.api_key, provider, api_key)}
    end

    def with_api_org(context, provider, api_org) do
      %{context | api_org: Map.put(context.api_org, provider, api_org)}
    end

    def with_setting(context, setting, value) do
      %{context | hyper_params: [{setting, value} | context.hyper_params]}
    end

    def with_safety_setting(context, safety_setting, threshold) do
      %{context | hyper_params: [ {:safety_setting, %{category: safety_setting, threshold: threshold}} | context.hyper_params]}
    end

    # Messages are not stored in settings, so these functions simply return the context unchanged.
    def with_message(context, _message), do: context
    def with_messages(context, _messages), do: context

    # Settings do not support streaming or direct inference execution.
    def stream(_, _), do: {:error, {:unsupported, GenAI.Settings}}
    def run(_), do: {:error, {:unsupported, GenAI.Settings}}
  end
end

defmodule GenAI.Chat do
  @moduledoc """
  This module defines the chat struct used to manage conversations with generative AI models.
  """

  @vsn 1.0

  defstruct [
    settings: %GenAI.Settings{},
    messages: [],
    vsn: @vsn
  ]


  defimpl GenAIProtocol do
    @moduledoc """
    Implements the `GenAIProtocol` for `GenAI.Chat`.

    This allows chat contexts to be used for configuring and running GenAI interactions.
    """

    # Delegate setting functions to the settings struct.
    def with_model(context, model) do
      %{context | settings: GenAIProtocol.with_model(context.settings, model)}
    end


    def with_tool(context, tool) do
      %{context | settings: GenAIProtocol.with_tool(context.settings, tool)}
    end
    def with_tools(context, tools) do
      %{context | settings: GenAIProtocol.with_tools(context.settings, tools)}
    end

    def with_api_key(context, provider, api_key) do
      %{context | settings: GenAIProtocol.with_api_key(context.settings, provider, api_key)}
    end

    def with_api_org(context, provider, api_org) do
      %{context | settings: GenAIProtocol.with_api_org(context.settings, provider, api_org)}
    end

    def with_setting(context, setting, value) do
      %{context | settings: GenAIProtocol.with_setting(context.settings, setting, value)}
    end

    def with_safety_setting(context, safety_setting, threshold) do
      %{context | settings: GenAIProtocol.with_safety_setting(context.settings, safety_setting, threshold)}
    end


    def with_message(context, message) do
      %{context | messages: [message | context.messages]}
    end

    def with_messages(context, messages) do
      %{context | messages: Enum.reverse(messages) ++ context.messages}
    end

    def stream(_context, _handler) do
      {:ok, :nyi}
    end

    @doc """
    Runs inference on the chat context.

    This function determines the final settings and model, prepares the messages, and then delegates the actual inference execution to the selected provider's `chat/3` function.
    """
    def run(context) do
      # Logic to pick/determine final set of settings, models, messages, with RAG/summarization.
      model = hd(context.settings.model)
      apply(model.provider, :chat, [context.messages, context.settings.tools, [{:model, model.model} | (context.settings.hyper_params)]])
    end
  end
end
