defmodule GenAI.Provider.Suno do
  @moduledoc """
  Suno music / sound generation provider (ADR-016). NOT an LLM — media only.

  Declares `text -> music` and `text -> sfx` as ASYNC: Suno generation is submit-then-poll,
  so `generate_media/2` submits the job and returns `{:ok, %GenAI.Media.Job{status: :pending}}`
  carrying the provider task id. The poll/download harness is owned by the audio/video lane
  (see `GenAI.Media.Job`); this provider implements the submit half.

  Suno has no single official public API — base_url + the generate path are configurable via
  `config :genai, :suno, base_url: "...", api_key: "...", generate_path: "/api/v1/generate"`.
  Auth is a Bearer key (`SUNO_API_KEY`).
  """
  @default_base_url "https://api.sunoapi.org"
  @default_generate_path "/api/v1/generate"
  @config_key :suno
  use GenAI.InferenceProviderBehaviour

  alias GenAI.Media.Request
  alias GenAI.Provider.MediaHelpers, as: H

  @impl GenAI.InferenceProviderBehaviour
  def supported_modalities do
    [
      %{input: [:text], output: :music, mode: :async},
      %{input: [:text], output: :sfx, mode: :async}
    ]
  end

  @impl GenAI.InferenceProviderBehaviour
  def generate_media(%Request{output: out} = req, _options) when out in [:music, :sfx] do
    with {:ok, key} <- H.require_key(req, "SUNO_API_KEY") do
      base = H.base_url(:suno, @default_base_url)
      path = req.settings[:generate_path] || generate_path()

      body =
        %{
          prompt: H.prompt_text(req.prompt),
          model: req.model || "V4_5",
          customMode: req.settings[:custom_mode] || false,
          instrumental: out == :sfx or (req.settings[:instrumental] || false)
        }
        |> Map.merge(req.settings[:body] || %{})

      case H.post_json(base <> path, key, body) do
        {:ok, %Finch.Response{status: status, body: resp}} when status in 200..299 ->
          {:ok, job(resp)}

        {:ok, %Finch.Response{status: status, body: resp}} ->
          {:error, {:http_error, status, resp}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    end
  end

  def generate_media(%Request{}, _options), do: {:error, :unsupported_modality}

  defp generate_path do
    :genai |> Application.get_env(:suno, []) |> Keyword.get(:generate_path, @default_generate_path)
  end

  defp job(resp) do
    {id, meta} =
      case Jason.decode(resp) do
        {:ok, %{"data" => %{"taskId" => task_id}} = json} -> {task_id, json}
        {:ok, %{"taskId" => task_id} = json} -> {task_id, json}
        {:ok, %{"id" => task_id} = json} -> {task_id, json}
        {:ok, json} -> {nil, json}
        _ -> {nil, %{}}
      end

    %GenAI.Media.Job{id: id, provider: __MODULE__, status: :pending, meta: meta}
  end
end
