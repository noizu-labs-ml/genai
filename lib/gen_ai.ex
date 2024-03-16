
defprotocol GenAIProtocol do
  def with_model(context, model)
  def with_api_key(context, provider, api_key)
  def with_api_org(context, provider, api_org)
  def with_setting(context, setting, value)
  def with_message(context, message)
  def with_messages(context, messages)
  def stream(context, handler)
  def run(context)
end

defmodule GenAI do

  def chat() do
    %GenAI.Chat{}
  end

  def with_model(context, model) do
    GenAIProtocol.with_model(context, model)
  end
  def with_api_key(context, provider, api_key) do
    GenAIProtocol.with_api_key(context, provider, api_key)
  end
  def with_api_org(context, provider, api_org) do
    GenAIProtocol.with_api_org(context, provider, api_org)
  end
  def with_setting(context, setting, value) do
    GenAIProtocol.with_setting(context, setting, value)
  end
  def with_message(context, message) do
    GenAIProtocol.with_message(context, message)
  end
  def with_messages(context, messages) do
    GenAIProtocol.with_messages(context, messages)
  end
  def stream(context, handler) do
    GenAIProtocol.stream(context, handler)
  end
  def run(context) do
    GenAIProtocol.run(context)
  end

end
