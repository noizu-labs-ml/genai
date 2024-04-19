
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
    def with_model(context, model, options) do
      %{context | settings: GenAIProtocol.with_model(context.settings, model, options)}
    end


    def with_tool(context, tool, options) do
      %{context | settings: GenAIProtocol.with_tool(context.settings, tool, options)}
    end
    def with_tools(context, tools, options) do
      %{context | settings: GenAIProtocol.with_tools(context.settings, tools, options)}
    end

    def with_api_key(context, provider, api_key, options) do
      %{context | settings: GenAIProtocol.with_api_key(context.settings, provider, api_key, options)}
    end

    def with_api_org(context, provider, api_org, options) do
      %{context | settings: GenAIProtocol.with_api_org(context.settings, provider, api_org, options)}
    end

    def with_setting(context, setting, value, options) do
      %{context | settings: GenAIProtocol.with_setting(context.settings, setting, value, options)}
    end
    def with_setting(context, setting,  _) do
      context
    end

    def with_safety_setting(context, safety_setting, threshold, options) do
      %{context | settings: GenAIProtocol.with_safety_setting(context.settings, safety_setting, threshold, options)}
    end


    def with_message(context, message,_) do
      %{context | messages: [message | context.messages]}
    end

    def with_messages(context, messages,_) do
      %{context | messages: Enum.reverse(messages) ++ context.messages}
    end

    def stream(_context, _handler, _) do
      {:ok, :nyi}
    end


    def tune_prompt(context, _, _) do
      context
    end

    def score(context, _, _) do
      context
    end

    def fitness(context, _, _) do
      context
    end
    def early_stopping(context, _, _) do
      context
    end
    def execute(context, _, _) do
      {:ok, :nyi}
    end





    @doc """
    Runs inference on the chat context.

    This function determines the final settings and model, prepares the messages, and then delegates the actual inference execution to the selected provider's `chat/3` function.
    """
    def run(context, _) do
      # Logic to pick/determine final set of settings, models, messages, with RAG/summarization.
      model = hd(context.settings.model)
      apply(model.provider, :chat, [context.messages |> Enum.reverse(), context.settings.tools, [{:model, model.model} | (context.settings.hyper_params)]])
    end
  end
end
