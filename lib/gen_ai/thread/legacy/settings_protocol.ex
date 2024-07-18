defprotocol GenAI.Thread.Legacy.SettingsProtocol do
  def with_model(context, model)
  def with_tool(context, tool)
  def with_tools(context, tools)
  def with_api_key(context, provider, api_key)
  def with_api_org(context, provider, api_org)
  def with_setting(context, setting, value)
  def with_safety_setting(context, safety_setting, threshold)
end
