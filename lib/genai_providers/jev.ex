defmodule GenAI.Provider.Jev do
  @moduledoc "Hosted TypeSafe Jev classifiers. This provider does not generate chat text."
  @behaviour GenAI.Classifier.ProviderBehaviour
  alias GenAI.Provider.SystemOne

  @impl true
  def classifier_capabilities,
    do: %{types: [:choice, :boolean, :score], modalities: [:text], max_choices: 255}

  @impl true
  def classify(request, options \\ []),
    do: SystemOne.classify(__MODULE__, request, settings(options), options)

  @doc "Discover hosted model aliases; pinned model IDs are also accepted."
  def models(options \\ []) do
    with {:ok, catalog} <- SystemOne.models(settings(options), options) do
      GenAI.Provider.Jev.Models.from_catalog(catalog)
    end
  end

  def run(_, _, _), do: {:error, :classifier_only_provider}
  def stream(_, _, _), do: {:error, :classifier_only_provider}

  defp settings(options) do
    config = Application.get_env(:genai, :jev, [])

    [
      base_url:
        options[:base_url] || config[:base_url] || System.get_env("JEV_BASE_URL") ||
          "https://api.typesafe.ai/v1",
      api_key:
        options[:api_key] || config[:api_key] || System.get_env("JEV_API_KEY") ||
          System.get_env("TYPESAFE_API_KEY"),
      model: options[:model_id] || config[:model] || "jev-latest"
    ]
  end
end
