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
    def with_model(context, model, _) do
      %{context | model: [model | context.model]}
    end

    def with_tool(context, tool, _) do
      %{context | tools: [tool | context.tools]}
    end
    def with_tools(context, tools, _) do
      %{context | tools: tools ++ context.tools}
    end

    def with_api_key(context, provider, api_key, _) do
      %{context | api_key: Map.put(context.api_key, provider, api_key)}
    end

    def with_api_org(context, provider, api_org, _) do
      %{context | api_org: Map.put(context.api_org, provider, api_org)}
    end

    def with_setting(context, setting, value, _) do
      %{context | hyper_params: [{setting, value} | context.hyper_params]}
    end
    def with_setting(context, setting, _) do
      context
    end

    def with_safety_setting(context, safety_setting, threshold, _) do
      %{context | hyper_params: [ {:safety_setting, %{category: safety_setting, threshold: threshold}} | context.hyper_params]}
    end

    # Messages are not stored in settings, so these functions simply return the context unchanged.
    def with_message(context, _message,_), do: context
    def with_messages(context, _messages,_), do: context

    # Settings do not support streaming or direct inference execution.
    def stream(_, _, _), do: {:error, {:unsupported, GenAI.Settings}}
    def run(_, _, _), do: {:error, {:unsupported, GenAI.Settings}}



  end
end
