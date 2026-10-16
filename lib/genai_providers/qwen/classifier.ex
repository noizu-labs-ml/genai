defmodule GenAI.Provider.Qwen.Classifier do
  @moduledoc "Alibaba decision-model-preview uses a separately configured workspace System One endpoint."
  @behaviour GenAI.Classifier.ProviderBehaviour

  @impl true
  def classifier_capabilities,
    do: %{types: [:choice, :boolean, :score], modalities: [:text], max_choices: 255}

  @impl true
  def classify(request, options \\ []) do
    config = Application.get_env(:genai, :qwen, [])

    settings = [
      base_url:
        options[:decision_base_url] || options[:base_url] || config[:decision_base_url] ||
          System.get_env("QWEN_DECISION_BASE_URL"),
      api_key:
        options[:api_key] || config[:decision_api_key] || config[:api_key] ||
          System.get_env("QWEN_API_KEY") || System.get_env("DASHSCOPE_API_KEY"),
      model: options[:model_id] || "decision-model-preview"
    ]

    GenAI.Provider.SystemOne.classify(GenAI.Provider.Qwen, request, settings, options)
  end
end
