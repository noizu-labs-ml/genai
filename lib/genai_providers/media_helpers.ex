defmodule GenAI.Provider.MediaHelpers do
  @moduledoc """
  Shared helpers for the sync media-generation providers (ADR-016 / ede43647): API-key
  resolution (request -> env, fast-fail when absent), prompt-text extraction, and the
  base64-image decode into the `{:ok, %{data, mime, meta}}` return contract. One
  definition reused by the OpenAI + Gemini image providers (and future media providers).
  """

  @doc "Resolve the API key from the request or env var; fast-fail (no doomed call) when unset."
  @spec require_key(GenAI.Media.Request.t(), String.t()) :: {:ok, String.t()} | {:error, :missing_api_key}
  def require_key(%GenAI.Media.Request{api_key: key}, _env) when is_binary(key) and key != "", do: {:ok, key}

  def require_key(%GenAI.Media.Request{}, env) do
    case System.get_env(env, "") do
      "" -> {:error, :missing_api_key}
      key -> {:ok, key}
    end
  end

  @doc "Flatten a request prompt (string or content parts) to the text the image API takes."
  @spec prompt_text(term) :: String.t()
  def prompt_text(prompt) when is_binary(prompt), do: prompt

  def prompt_text(parts) when is_list(parts) do
    parts
    |> Enum.map(fn
      %{__struct__: GenAI.Message.Content.TextContent, text: t} when is_binary(t) -> t
      t when is_binary(t) -> t
      _ -> ""
    end)
    |> Enum.join(" ")
    |> String.trim()
  end

  def prompt_text(_), do: ""

  @doc """
  Decode a provider JSON image response: pull the base64 string at `path`
  (e.g. `["data", access0(), "b64_json"]`) and decode into the media return map.
  """
  @spec decode_image(binary, list, String.t()) ::
          {:ok, %{data: binary, mime: String.t(), meta: map}} | {:error, term}
  def decode_image(body, path, mime \\ "image/png") do
    with {:ok, json} <- Jason.decode(body),
         b64 when is_binary(b64) <- get_in(json, path),
         {:ok, bytes} <- Base.decode64(b64) do
      {:ok, %{data: bytes, mime: mime, meta: %{}}}
    else
      _ -> {:error, :unexpected_response}
    end
  end

  @doc "Access helper for the first element of a list inside a get_in path."
  def access0, do: Access.at(0)
end
