defprotocol GenAIProtocol do

  @doc """
  Specify a specific model or model picker.

  This function allows you to define the model to be used for inference. You can either provide a specific model, like `Model.smartest()`, or a model picker function that dynamically selects the best model based on the context and available providers.

  Examples:
  * `Model.smartest()` - This will select the "smartest" available model at inference time, based on factors like performance and capabilities.
  * `Model.cheapest(params: :best_effort)` - This will select the cheapest available model that can handle the given parameters and context size.
  * `CustomProvider.custom_model` - This allows you to use a custom model from a user-defined provider.
  """
  def with_model(context, model, options)

  def with_tool(context, tool, options)
  def with_tools(context, tools, options)

  @doc """
  Specify an API key for a provider.
  """
  def with_api_key(context, provider, api_key, options)

  @doc """
  Specify an API org for a provider.
  """
  def with_api_org(context, provider, api_org, options)

  @doc """
  Set a hyperparameter option.

  Some options are model-specific. The value can be a literal or a picker function that dynamically determines the best value based on the context and model.

  Examples:
  * `Parameter.required(name, value)` - This sets a required parameter with the specified name and value.
  * `Gemini.best_temperature_for(:chain_of_thought)` - This uses a picker function to determine the best temperature for the Gemini provider when using the "chain of thought" prompting technique.
  """
  def with_setting(context, setting, value, options)
  def with_setting(context, setting, options)

  def with_safety_setting(context, safety_setting, threshold, options)

  @doc """
  Add a message to the conversation.
  """
  def with_message(context, message, options)

  @doc """
  Add a list of messages to the conversation.
  """
  def with_messages(context, messages, options)

  @doc """
  Start inference using a streaming handler.

  If the selected model does not support streaming, the handler will be called with the final inference result.
  """
  def stream(context, handler, options)

  @doc """
  Run inference.

  This function performs the following steps:
  * Picks the appropriate model and hyperparameters based on the provided context and settings.
  * Performs any necessary pre-processing, such as RAG (Retrieval-Augmented Generation) or message consolidation.
  * Runs inference on the selected model with the prepared input.
  * Returns the inference result.
  """
  def run(context, options)



  def tag(context, tag, options)
  def loop(context, tag, iterator, options)
  def enter_loop(context, loop)
  def exit_loop(context, loop)

  def tune_prompt(context, handle, options)
  def score(context, scorer, options)
  def fitness(context, fitness, options)
  def early_stopping(context, sentinel, options)
  def execute(context, type, options)

end

defimpl GenAIProtocol, for: Tuple do
  def with_model({:ok, context}, model, options), do: GenAIProtocol.with_model(context, model, options)
  def with_model(error = {:error, _}, _model, _options), do: error

  def with_tool({:ok, context}, tool, options), do: GenAIProtocol.with_tool(context, tool, options)
  def with_tool(error = {:error, _}, _tool, _options), do: error

  def with_tools({:ok, context}, tools, options), do: GenAIProtocol.with_tools(context, tools, options)
  def with_tools(error = {:error, _}, _tools, _options), do: error

  def with_api_key({:ok, context}, provider, api_key, options), do: GenAIProtocol.with_api_key(context, provider, api_key, options)
  def with_api_key(error = {:error, _}, _provider, _api_key, _options), do: error

  def with_api_org({:ok, context}, provider, api_org, options), do: GenAIProtocol.with_api_org(context, provider, api_org, options)
  def with_api_org(error = {:error, _}, _provider, _api_org, _options), do: error

  def with_setting({:ok, context}, setting, value, options), do: GenAIProtocol.with_setting(context, setting, value, options)
  def with_setting(error = {:error, _}, _setting, _value, _options), do: error

  def with_setting({:ok, context}, setting, options), do: GenAIProtocol.with_setting(context, setting, options)
  def with_setting(error = {:error, _}, _setting, _options), do: error

  def with_safety_setting({:ok, context}, safety_setting, threshold, options), do: GenAIProtocol.with_safety_setting(context, safety_setting, threshold, options)
  def with_safety_setting(error = {:error, _}, _safety_setting, _threshold, _options), do: error

  def with_message({:ok, context}, message, options), do: GenAIProtocol.with_message(context, message, options)
  def with_message(error = {:error, _}, _message, _options), do: error

  def with_messages({:ok, context}, messages, options), do: GenAIProtocol.with_messages(context, messages, options)
  def with_messages(error = {:error, _}, _messages, _options), do: error

  def stream({:ok, context}, handler, options), do: GenAIProtocol.stream(context, handler, options)
  def stream(error = {:error, _}, _handler, _options), do: error

  def run({:ok, context}, options), do: GenAIProtocol.run(context, options)
  def run(error = {:error, _}, _options), do: error

  def tag({:ok, context}, tag, options), do: GenAIProtocol.tag(context, tag, options)
  def tag(error = {:error, _}, _tag, _options), do: error

  def loop({:ok, context}, tag, iterator, options), do: GenAIProtocol.loop(context, tag, iterator, options)
  def loop(error = {:error, _}, _tag, _iterator, _options), do: error

  def enter_loop({:ok, context}, node), do: GenAIProtocol.enter_loop(context, node)
  def enter_loop(error = {:error, _}, _node), do: error

  def exit_loop({:ok, context}, node), do: GenAIProtocol.exit_loop(context, node)
  def exit_loop(error = {:error, _}, _node), do: error


  def tune_prompt({:ok, context}, handle, options), do: GenAIProtocol.tune_prompt(context, handle, options)
  def tune_prompt(error = {:error, _}, _handle, _options), do: error

  def score({:ok, context}, scorer, options), do: GenAIProtocol.score(context, scorer, options)
  def score(error = {:error, _}, _scorer, _options), do: error

  def fitness({:ok, context}, fitness, options), do: GenAIProtocol.fitness(context, fitness, options)
  def fitness(error = {:error, _}, _fitness, _options), do: error

  def early_stopping({:ok, context}, sentinel, options), do: GenAIProtocol.early_stopping(context, sentinel, options)
  def early_stopping(error = {:error, _}, _sentinel, _options), do: error

  def execute({:ok, context}, type, options), do: GenAIProtocol.execute(context, type, options)
  def execute(error = {:error, _}, _type, _options), do: error

end
