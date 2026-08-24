defmodule GenAI.Provider.MediaHelpers do
  @moduledoc """
  Shared helpers for the sync media-generation providers (ADR-016 / ede43647): API-key
  resolution (request -> env, fast-fail when absent), prompt-text extraction, and the
  base64-image decode into the `{:ok, %{data, mime, meta}}` return contract. One
  definition reused by the OpenAI + Gemini image providers (and future media providers).
  """

  @doc "Resolve the API key from the request or env var; fast-fail (no doomed call) when unset."
  @spec require_key(GenAI.Media.Request.t(), String.t()) ::
          {:ok, String.t()} | {:error, :missing_api_key}
  # ⟦𓎝𓏓𓄗𓄪⟧ require_key :: Resolve the API key from the request or env var; fast-fail (no doomed call) when unset.
  def require_key(%GenAI.Media.Request{api_key: key}, _env) when is_binary(key) and key != "",
    do: {:ok, key}

  def require_key(%GenAI.Media.Request{}, env) do
    case System.get_env(env, "") do
      "" -> {:error, :missing_api_key}
      key -> {:ok, key}
    end
  end

  @doc "Flatten a request prompt (string or content parts) to the text the image API takes."
  @spec prompt_text(term) :: String.t()
  # ⟦𓄰𓆘𓏩𓐤⟧ prompt_text :: Flatten a request prompt (string or content parts) to the text the image API takes.
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
  # ⟦𓎉𓍠𓊡𓏩⟧ decode_image :: auto-generated pointer for public function decode_image
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
  # ⟦𓎁𓅜𓄝𓌿⟧ access0 :: Access helper for the first element of a list inside a get_in path.
  def access0, do: Access.at(0)

  @doc "Decode a JSON response and pull a string field (e.g. a transcript) at `path`."
  @spec decode_text(binary, list, String.t()) ::
          {:ok, %{data: String.t(), mime: String.t(), meta: map}} | {:error, term}
  # ⟦𓊡𓊚𓈗𓅆⟧ decode_text :: auto-generated pointer for public function decode_text
  def decode_text(body, path, mime \\ "text/plain") do
    with {:ok, json} <- Jason.decode(body),
         text when is_binary(text) <- get_in(json, path) do
      {:ok, %{data: text, mime: mime, meta: %{}}}
    else
      _ -> {:error, :unexpected_response}
    end
  end

  @doc "Wrap a raw-binary provider response (e.g. TTS audio bytes) into the media contract."
  @spec binary_result(binary, String.t()) :: {:ok, %{data: binary, mime: String.t(), meta: map}}
  # ⟦𓍌𓊎𓁿𓉪⟧ binary_result :: Wrap a raw-binary provider response (e.g.
  def binary_result(body, mime), do: {:ok, %{data: body, mime: mime, meta: %{}}}

  @doc "Runtime base_url for a provider, read from `config :genai, <config_key>, base_url:`."
  @spec base_url(atom, String.t()) :: String.t()
  # ⟦𓎯𓍺𓇐𓌑⟧ base_url :: Runtime base_url for a provider, read from `config :genai, <config_key>, base_url:`.
  def base_url(config_key, default) do
    :genai |> Application.get_env(config_key, []) |> Keyword.get(:base_url, default)
  end

  @doc "Default Finch options for media calls — image/audio/video generation can be slow."
  # ⟦𓏻𓎖𓉪𓌂⟧ media_opts :: Default Finch options for media calls — image/audio/video generation can be slow.
  def media_opts(extra \\ []), do: Keyword.merge([receive_timeout: 120_000], extra)

  @multipart_boundary "----genaiMediaFormBoundary8x7vQ2"

  @doc """
  Build a `multipart/form-data` request: `fields` is a keyword of string values, `file`
  is `{field, filename, binary, content_type}` (or nil). Returns `{content_type, body}` for
  a raw Finch POST — NOT for `api_call/5`, which JSON-encodes its body.
  """
  @spec multipart(keyword, {atom | String.t(), String.t(), binary, String.t()} | nil) ::
          {String.t(), binary}
  # ⟦𓋚𓂋𓀗𓃡⟧ multipart :: auto-generated pointer for public function multipart
  def multipart(fields, file \\ nil) do
    field_parts =
      Enum.map(fields, fn {k, v} ->
        "--#{@multipart_boundary}\r\nContent-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
      end)

    file_part =
      case file do
        nil ->
          []

        {field, filename, bin, ctype} ->
          [
            "--#{@multipart_boundary}\r\nContent-Disposition: form-data; name=\"#{field}\"; filename=\"#{filename}\"\r\nContent-Type: #{ctype}\r\n\r\n",
            bin,
            "\r\n"
          ]
      end

    body = IO.iodata_to_binary([field_parts, file_part, "--#{@multipart_boundary}--\r\n"])
    {"multipart/form-data; boundary=#{@multipart_boundary}", body}
  end

  @doc "Raw Finch POST (body sent verbatim, not JSON-encoded) — for multipart/form uploads."
  @spec raw_post(String.t(), list, binary, keyword) ::
          {:ok, Finch.Response.t()} | {:error, term}
  # ⟦𓉘𓋜𓊧𓅫⟧ raw_post :: auto-generated pointer for public function raw_post
  def raw_post(url, headers, body, options \\ []) do
    Finch.build(:post, url, headers, body)
    |> Finch.request(GenAI.Finch, media_opts(options))
  end

  @doc "Bearer-authed JSON POST (body JSON-encoded). Returns the raw Finch response."
  @spec post_json(String.t(), String.t(), map, keyword) ::
          {:ok, Finch.Response.t()} | {:error, term}
  # ⟦𓉐𓂛𓀢𓆑⟧ post_json :: auto-generated pointer for public function post_json
  def post_json(url, key, body, options \\ []) do
    extra = Keyword.get(options, :headers, [])

    with {:ok, json} <- Jason.encode(body) do
      headers =
        [{"authorization", "Bearer #{key}"}, {"content-type", "application/json"}] ++ extra

      Finch.build(:post, url, headers, json)
      |> Finch.request(GenAI.Finch, media_opts(Keyword.delete(options, :headers)))
    end
  end

  @doc "HTTP GET (optional headers). Used to download DashScope result URLs."
  @spec get(String.t(), list, keyword) :: {:ok, Finch.Response.t()} | {:error, term}
  def get(url, headers \\ [], options \\ []) do
    Finch.build(:get, url, headers)
    |> Finch.request(GenAI.Finch, media_opts(options))
  end

  @doc "Download a URL to raw bytes (2xx)."
  @spec download(String.t(), keyword) :: {:ok, binary} | {:error, term}
  def download(url, options \\ []) do
    case get(url, [], options) do
      {:ok, %Finch.Response{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %Finch.Response{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Map a common audio response_format (extension) to its MIME type."
  # ⟦𓄘𓇫𓂗𓆠⟧ audio_mime :: Map a common audio response_format (extension) to its MIME type.
  def audio_mime(fmt) do
    case to_string(fmt) do
      "mp3" -> "audio/mpeg"
      "opus" -> "audio/opus"
      "aac" -> "audio/aac"
      "flac" -> "audio/flac"
      "wav" -> "audio/wav"
      "pcm" -> "audio/pcm"
      _ -> "application/octet-stream"
    end
  end
end
