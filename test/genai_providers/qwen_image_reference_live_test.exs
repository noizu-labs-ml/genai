defmodule GenAI.Provider.QwenImageReferenceLiveTest do
  @moduledoc """
  ONE real qwen-image-3.0-pro reference-image edit (image+text -> image) over the
  DashScope intl multimodal route. Gated on QWEN_API_KEY (direnv sk- intl; the dc
  MaaS token 401s AIGC routes). This is the no-stubs proof for the media-tool-site
  revision leg. Run with: mix test --only live test/genai_providers/qwen_image_reference_live_test.exs
  """
  use ExUnit.Case, async: false
  @moduletag :live
  # The sync multimodal render sits behind a ~61s server ceiling (plus connection-drop
  # retries); ExUnit's default 60s test timeout would kill an in-progress render.
  @moduletag timeout: 300_000

  alias GenAI.Media.Request
  alias GenAI.Message.Content.ImageContent
  alias GenAI.Provider.Qwen.Image, as: QwenImage

  @fixture Path.expand("../fixtures/reference.png", __DIR__)

  defp redact(term, key) do
    inspected = inspect(term, limit: 8, printable_limit: 400)
    if is_binary(key) and key != "", do: String.replace(inspected, key, "[REDACTED]"), else: inspected
  end

  test "qwen-image-3.0-pro edits a reference image (real multimodal call, explicit size)" do
    key =
      System.get_env("QWEN_API_KEY") || System.get_env("DASHSCOPE_API_KEY") ||
        System.get_env("QWEN_TOKEN_KEY")

    if is_nil(key) or key == "", do: flunk("Unmet live prerequisite: QWEN_API_KEY")

    bytes = File.read!(@fixture)
    image = ImageContent.new({:base64, Base.encode64(bytes)}, type: :png)

    req = %Request{
      output: :image,
      model: "qwen-image-3.0-pro",
      prompt: [image, "Repaint this scene in warm sunset colors; keep the composition."],
      api_key: key,
      settings: %{size: "1600x900"}
    }

    case QwenImage.generate_media(req, []) do
      {:ok, %{data: data, mime: mime, meta: meta}} ->
        assert byte_size(data) > 1_000, "expected non-trivial image bytes"
        assert mime == "image/png"
        IO.puts("LIVE qwen-image reference: OK bytes=#{byte_size(data)} url_present=#{is_binary(meta[:url])}")

      {:error, reason} ->
        flunk("LIVE qwen-image reference FAILED (redacted): " <> redact(reason, key))
    end
  end
end