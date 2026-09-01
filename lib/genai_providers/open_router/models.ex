defmodule GenAI.Provider.OpenRouter.Models do
  @moduledoc """
  Convenience constructors for OpenRouter model slugs (`author/slug`).

  Any id `GET /api/v1/models` returns can be wrapped with `model/1`. Named
  helpers cover common commercial aliases; the live catalog is large and changes.
  """
  import GenAI.InferenceProvider.Helpers

  def load_metadata(_ \\ nil), do: :ok

  def list(options \\ nil) do
    headers = GenAI.Provider.OpenRouter.headers(options)
    call = api_call(:get, "#{GenAI.Provider.OpenRouter.base_url()}/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      case json do
        %{data: models} when is_list(models) -> {:ok, Enum.map(models, &model_from_json/1)}
        _ -> {:error, {:response, json}}
      end
    end
  end

  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.OpenRouter,
      encoder: GenAI.Provider.OpenRouter.Encoder
    }
  end

  def gpt_latest(), do: model("~openai/gpt-latest")
  def gpt_4o(), do: model("openai/gpt-4o")
  def gpt_4o_mini(), do: model("openai/gpt-4o-mini")
  def claude_sonnet_4(), do: model("anthropic/claude-sonnet-4")
  def gemini_2_5_flash(), do: model("google/gemini-2.5-flash")
  def gemini_2_5_pro(), do: model("google/gemini-2.5-pro")
  def gemini_3_7_flash(), do: model("google/gemini-3.7-flash")
  def llama_3_3_70b(), do: model("meta-llama/llama-3.3-70b-instruct")
  def qwen3_8_27b(), do: model("qwen/qwen3.8-27b")

  defp model_metadata_provider do
    Application.get_env(:genai, :openrouter, [])[:metadata_provider] ||
      GenAI.ModelMetadata.DefaultProvider
  end

  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        model_metadata_provider(),
        GenAI.Provider.OpenRouter,
        json[:id]
      )

    entry
  end
end
