defmodule GenAI.Thread.Legacy.Settings do
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


  defimpl GenAI.Thread.Legacy.SettingsProtocol do
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

  end

  defimpl GenAI.Thread.StateProtocol do
      def with_model(state, model) do
        {:ok, %{state | model: [model | state.model]}}
      end
   end

end
