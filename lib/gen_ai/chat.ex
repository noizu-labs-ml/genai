defmodule GenAI.Settings do
  @vsn 1.0
  defstruct [
    model: [],
    api_key: %{},
    api_org: %{},
    hyper_params: [],
    vsn: @vsn
  ]



  defimpl GenAIProtocol do
    def with_model(context, model) do
      %{context| model: [model|context.model]}
    end
    def with_api_key(context, provider, api_key) do
      %{context| api_key: Map.put(context.api_key, provider, api_key)}
    end
    def with_api_org(context, provider, api_org) do
      %{context| api_org: Map.put(context.api_org, provider, api_org)}
    end
    def with_setting(context, setting, value) do
      %{context| hyper_params: [{setting, value}|context.hyper_params]}
    end
    def with_message(context, _) do
      context
    end
    def with_messages(context, _) do
      context
    end
    def stream(_, _) do
      {:error, {:unsupported, GenAI.Settings}}
    end
    def run(_) do
      {:error, {:unsupported, GenAI.Settings}}
    end
  end

end

defmodule GenAI.Chat do
  @vsn 1.0
  defstruct [
    settings: %GenAI.Settings{},
    messages: [],
    vsn: @vsn
  ]



  defimpl GenAIProtocol do
    def with_model(context, model) do
      %{context| settings: GenAIProtocol.with_model(context.settings, model)}
    end
    def with_api_key(context, provider, api_key) do
      %{context| settings: GenAIProtocol.with_api_key(context.settings, provider, api_key)}
    end
    def with_api_org(context, provider, api_org) do
      %{context| settings: GenAIProtocol.with_api_org(context.settings, provider, api_org)}
    end
    def with_setting(context, setting, value) do
      %{context| settings: GenAIProtocol.with_setting(context.settings, setting, value)}
    end
    def with_message(context, message) do
      %{context| messages: [message|context.messages]}
    end
    def with_messages(context, messages) do
      %{context| messages: Enum.reverse(messages) ++ context.messages}
    end
    def stream(_context, _handler) do
      {:ok, :nyi}
    end
    def run(context) do
      # Logic to pick/determine final set of settings, models, messages, with rag/summarization.
      model = hd(context.settings.model)
      apply(model.provider, :chat, [context.messages, nil, [model: model.model]])
    end
  end

end
