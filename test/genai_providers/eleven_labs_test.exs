defmodule GenAI.Provider.ElevenLabsTest do
  @moduledoc """
  ElevenLabs media provider (ADR-016): sync text->speech (TTS), text->sfx, and text->music
  against the official api.elevenlabs.io endpoints (xi-api-key auth). Finch is mocked via
  Mimic — no live API. Plus routing via GenAI.generate_media with an explicit provider.
  """
  use ExUnit.Case, async: false
  use Mimic

  alias GenAI.Media.Request
  alias GenAI.Provider.ElevenLabs

  @audio <<1, 2, 3, 4, 5, 6>>

  setup do
    keys = ~w(ELEVENLABS_API_KEY)
    saved = Map.new(keys, &{&1, System.get_env(&1)})
    Enum.each(keys, &System.delete_env/1)

    on_exit(fn ->
      Enum.each(saved, fn
        {k, nil} -> System.delete_env(k)
        {k, v} -> System.put_env(k, v)
      end)
    end)

    :ok
  end

  defp stub_finch(fun) when is_function(fun, 1),
    do: stub(Finch, :request, fn req, GenAI.Finch, _opts -> fun.(req) end)

  defp ok200(body), do: {:ok, %Finch.Response{status: 200, body: body}}

  describe "modality declarations" do
    test "declares text -> speech/sfx/music, all sync" do
      assert [
               %{input: [:text], output: :speech, mode: :sync},
               %{input: [:text], output: :sfx, mode: :sync},
               %{input: [:text], output: :music, mode: :sync}
             ] = ElevenLabs.supported_modalities()
    end

    test "undeclared output -> unsupported_modality" do
      assert {:error, :unsupported_modality} =
               ElevenLabs.generate_media(%Request{output: :image, prompt: "cat"}, [])
    end
  end

  describe "api key resolution" do
    test "no key -> fast fail (speech)" do
      assert {:error, :missing_api_key} =
               ElevenLabs.generate_media(%Request{output: :speech, prompt: "hi"}, [])
    end

    test "no key -> fast fail (music)" do
      assert {:error, :missing_api_key} =
               ElevenLabs.generate_media(%Request{output: :music, prompt: "lofi"}, [])
    end

    test "env var supplies the key" do
      System.put_env("ELEVENLABS_API_KEY", "xi-env")
      stub_finch(fn req ->
        assert {"xi-api-key", "xi-env"} in req.headers
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio}} =
               ElevenLabs.generate_media(%Request{output: :sfx, prompt: "boom"}, [])
    end
  end

  describe "text -> speech (TTS)" do
    test "posts to /v1/text-to-speech/{voice_id} with default model + format" do
      stub_finch(fn req ->
        assert req.method == "POST"
        assert req.host == "api.elevenlabs.io"
        assert req.path == "/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM"
        assert req.query == "output_format=mp3_44100_128"
        assert {"xi-api-key", "xi-1"} in req.headers
        assert req.body =~ "\"model_id\":\"eleven_multilingual_v2\""
        assert req.body =~ "\"text\":\"hello there\""
        refute req.body =~ "voice_settings"
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio, mime: "audio/mpeg", meta: %{}}} =
               ElevenLabs.generate_media(
                 %Request{output: :speech, prompt: "hello there", api_key: "xi-1"},
                 []
               )
    end

    test "honors voice_id + model overrides and passes voice_settings" do
      stub_finch(fn req ->
        assert req.path =~ "/v1/text-to-speech/abcVOICExyz"
        assert req.query == "output_format=mp3_44100_128"
        assert req.body =~ "\"model_id\":\"eleven_turbo_v2_5\""
        assert req.body =~ "\"stability\":0.2"
        assert req.body =~ "\"speed\":1.5"
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio}} =
               ElevenLabs.generate_media(
                 %Request{
                   output: :speech,
                   prompt: "hi",
                   api_key: "xi-1",
                   model: "eleven_turbo_v2_5",
                   settings: %{
                     voice_id: "abcVOICExyz",
                     stability: 0.2,
                     speed: 1.5
                   }
                 },
                 []
               )
    end

    test "wav output_format maps the mime" do
      stub_finch(fn req ->
        assert req.query == "output_format=pcm_44100"
        ok200(@audio)
      end)

      assert {:ok, %{mime: "audio/pcm"}} =
               ElevenLabs.generate_media(
                 %Request{
                   output: :speech,
                   prompt: "hi",
                   api_key: "xi-1",
                   settings: %{format: "pcm_44100"}
                 },
                 []
               )
    end
  end

  describe "text -> sfx (sound generation)" do
    test "posts to /v1/sound-generation with text only by default" do
      stub_finch(fn req ->
        assert req.path == "/v1/sound-generation"
        assert {"xi-api-key", "xi-1"} in req.headers
        assert req.body =~ "\"text\":\"thunder crack\""
        refute req.body =~ "duration_seconds"
        refute req.body =~ "prompt_influence"
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio, mime: "audio/mpeg"}} =
               ElevenLabs.generate_media(
                 %Request{output: :sfx, prompt: "thunder crack", api_key: "xi-1"},
                 []
               )
    end

    test "passes duration_seconds + prompt_influence" do
      stub_finch(fn req ->
        assert req.body =~ "\"duration_seconds\":3.5"
        assert req.body =~ "\"prompt_influence\":0.8"
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio}} =
               ElevenLabs.generate_media(
                 %Request{
                   output: :sfx,
                   prompt: "boom",
                   api_key: "xi-1",
                   settings: %{duration_seconds: 3.5, prompt_influence: 0.8}
                 },
                 []
               )
    end
  end

  describe "text -> music (compose)" do
    test "posts to /v1/music/compose with prompt + music_v1 + auto format" do
      stub_finch(fn req ->
        assert req.path == "/v1/music/compose"
        assert req.query == "output_format=auto"
        assert req.body =~ "\"prompt\":\"lofi beats\""
        assert req.body =~ "\"model_id\":\"music_v1\""
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio, mime: "audio/mpeg"}} =
               ElevenLabs.generate_media(
                 %Request{output: :music, prompt: "lofi beats", api_key: "xi-1"},
                 []
               )
    end

    test "supports music_v2 + length/instrumental knobs" do
      stub_finch(fn req ->
        assert req.body =~ "\"model_id\":\"music_v2\""
        assert req.body =~ "\"music_length_ms\":30000"
        assert req.body =~ "\"force_instrumental\":true"
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio}} =
               ElevenLabs.generate_media(
                 %Request{
                   output: :music,
                   prompt: "jazz",
                   api_key: "xi-1",
                   model: "music_v2",
                   settings: %{music_length_ms: 30_000, force_instrumental: true}
                 },
                 []
               )
    end
  end

  describe "error handling" do
    test "non-200 -> http_error" do
      stub_finch(fn _req -> {:ok, %Finch.Response{status: 401, body: "{\"detail\":\"denied\"}"}} end)

      assert {:error, {:http_error, 401, body}} =
               ElevenLabs.generate_media(
                 %Request{output: :speech, prompt: "hi", api_key: "xi-bad"},
                 []
               )

      assert body =~ "denied"
    end

    test "transport failure -> request_failed" do
      stub_finch(fn _req -> {:error, :econnrefused} end)

      assert {:error, {:request_failed, :econnrefused}} =
               ElevenLabs.generate_media(
                 %Request{output: :speech, prompt: "hi", api_key: "xi-1"},
                 []
               )
    end
  end

  describe "routing (GenAI.generate_media)" do
    test "explicit provider module routes to ElevenLabs" do
      stub_finch(fn req ->
        assert req.path =~ "/v1/sound-generation"
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio}} =
               GenAI.generate_media(%Request{
                 output: :sfx,
                 prompt: "zap",
                 provider: ElevenLabs,
                 api_key: "xi-1"
               })
    end

    test "provider config-key atom routes to ElevenLabs" do
      stub_finch(fn req ->
        assert req.path =~ "/v1/music/compose"
        ok200(@audio)
      end)

      assert {:ok, %{data: @audio}} =
               GenAI.generate_media(%Request{
                 output: :music,
                 prompt: "jazz",
                 provider: :eleven_labs,
                 api_key: "xi-1"
               })
    end
  end
end
