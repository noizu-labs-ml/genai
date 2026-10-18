defmodule GenAI.Provider.Jev.Local do
  @moduledoc """
  Optional local Jev-Omni bridge. Consumers install ExLLama and load a classifier
  explicitly; GenAI has no native build dependency and imports no native structs.
  """
  @behaviour GenAI.Classifier.ProviderBehaviour

  @impl true
  def classifier_capabilities,
    do: %{
      types: [:choice, :boolean, :score],
      modalities: [:text],
      max_choices: 256,
      native_multi_question: false
    }

  @doc "Construct a local classifier model reference, separate from hosted TypeSafe Jev."
  def model(name \\ "akhilaaa3/Jev-Omni"), do: %GenAI.Model{model: name, provider: __MODULE__}

  @doc "Load local model/head assets through an installed ExLLama backend."
  def load(model_path, head_path, options \\ []) do
    with {:ok, backend} <- backend(options, :load_classifier, 3) do
      case apply(backend, :load_classifier, [
             model_path,
             head_path,
             Keyword.drop(options, [:backend])
           ]) do
        {:ok, _} = success -> success
        error -> redact_error(error)
      end
    end
  rescue
    _ -> {:error, :local_classifier_load_failed}
  end

  @impl true
  def classify(request, options \\ []) do
    config = Application.get_env(:genai, :jev_local, [])
    loaded = options[:classifier] || config[:classifier]

    with {:ok, request} <- GenAI.Classifier.Request.normalize(request),
         false <- is_nil(loaded),
         {:ok, backend} <- backend(options, :classify, 3),
         {:ok, result} <-
           apply(backend, :classify, [
             loaded,
             request,
             Keyword.drop(options, [:backend, :classifier])
           ]),
         {:ok, result} <- GenAI.Classifier.Result.normalize(result, request) do
      # Native results carry engine diagnostics; copy only known non-credential
      # fields rather than arbitrary backend metadata or request options.
      safe_metadata =
        Map.take(result.metadata, [
          :duration_unit,
          :head_format,
          :head_sha256,
          :native_multi_question,
          :forward_passes
        ])

      answers =
        Enum.map(result.answers, fn answer ->
          %{
            answer
            | metadata: Map.take(answer.metadata, [:pooling, :normalization, :head_precision]),
              confidence_metadata: Map.take(answer.confidence_metadata, [:meaning])
          }
        end)

      usage =
        if is_map(result.usage) do
          result.usage
          |> Map.take([
            :prompt_tokens,
            :completion_tokens,
            :total_tokens,
            "input_tokens",
            "output_tokens",
            "total_tokens"
          ])
          |> Enum.filter(fn {_key, value} -> is_integer(value) and value >= 0 end)
          |> Map.new()
        else
          nil
        end

      {:ok,
       %{
         result
         | answers: answers,
           provider: __MODULE__,
           model: request.model || model(),
           usage: usage,
           metadata: safe_metadata
       }}
    else
      true -> {:error, :loaded_local_classifier_required}
      {:error, _} = error -> redact_error(error)
      _ -> {:error, :invalid_local_classifier_response}
    end
  rescue
    _ -> {:error, :local_classifier_inference_failed}
  end

  def run(_, _, _), do: {:error, :classifier_only_provider}
  def stream(_, _, _), do: {:error, :classifier_only_provider}

  defp backend(options, function, arity) do
    backend = Keyword.get(options, :backend, ExLLama)

    if is_atom(backend) and Code.ensure_loaded?(backend) and
         function_exported?(backend, function, arity),
       do: {:ok, backend},
       else: {:error, :local_classifier_backend_unavailable}
  end

  defp redact_error({:error, reason}) when is_atom(reason), do: {:error, reason}
  defp redact_error(_), do: {:error, :local_classifier_inference_failed}
end
