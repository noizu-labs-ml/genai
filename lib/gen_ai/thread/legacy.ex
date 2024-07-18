
defmodule GenAI.Thread.Legacy do
  @moduledoc """
  This module defines the chat struct used to manage conversations with generative AI models.
  """

  @vsn 1.0

  defstruct [
    settings: %GenAI.Thread.Legacy.Settings{},
    messages: [],
    vsn: @vsn
  ]


  defimpl GenAI.ThreadProtocol do
    @moduledoc """
    Implements the `GenAI.ThreadProtocol` for `GenAI.Thread.Legacy`.

    This allows chat contexts to be used for configuring and running GenAI interactions.
    """
    alias GenAI.Thread.Legacy.SettingsProtocol

    # Delegate setting functions to the settings struct.
    def with_model(context, model) do
      %{context | settings: SettingsProtocol.with_model(context.settings, model)}
    end


    def with_tool(context, tool) do
      %{context | settings: SettingsProtocol.with_tool(context.settings, tool)}
    end
    def with_tools(context, tools) do
      %{context | settings: SettingsProtocol.with_tools(context.settings, tools)}
    end

    def with_api_key(context, provider, api_key) do
      %{context | settings: SettingsProtocol.with_api_key(context.settings, provider, api_key)}
    end

    def with_api_org(context, provider, api_org) do
      %{context | settings: SettingsProtocol.with_api_org(context.settings, provider, api_org)}
    end

    def with_setting(context, setting, value) do
      %{context | settings: SettingsProtocol.with_setting(context.settings, setting, value)}
    end

    def with_safety_setting(context, safety_setting, threshold) do
      %{context | settings: SettingsProtocol.with_safety_setting(context.settings, safety_setting, threshold)}
    end


    def with_message(context, message,_) do
      %{context | messages: [message | context.messages]}
    end

    def with_messages(context, messages,_) do
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
      apply(model.provider, :chat, [context.messages |> Enum.reverse(), context.settings.tools, [{:model, model.model} | (context.settings.hyper_params)]])
    end
  end
end
