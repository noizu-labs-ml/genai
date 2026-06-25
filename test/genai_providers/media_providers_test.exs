defmodule GenAI.Provider.MediaProvidersTest do
  @moduledoc """
  ADR-016 media providers beyond image: OpenAI speech (TTS) + transcription (STT), the
  LiteLLM proxy media dispatcher, and Suno (async music/sfx). Plus end-to-end routing via
  GenAI.generate_media against the configured registry. Finch is mocked via Mimic.
  """
  use ExUnit.Case, async: false
  use Mimic

  alias GenAI.Media.Request
  alias GenAI.Provider.OpenAI
  alias GenAI.Provider.LiteLLM
  alias GenAI.Provider.Suno

  @audio <<0, 1, 2, 3, 4, 5>>
  @png <<137, 80, 78, 71>>
  @png_b64 Base.encode64(@png)

  setup do
    keys = ~w(OPENAI_API_KEY GEMINI_API_KEY LITELLM_API_KEY SUNO_API_KEY)
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

  defp stub_finch(fun), do: stub(Finch, :request, fn _req, GenAI.Finch, _opts -> fun.() end)
  defp ok200(body), do: {:ok, %Finch.Response{status: 200, body: body}}

  describe "OpenAI.Speech (TTS, text -> speech)" do
    test "declares text -> speech sync" do
      assert [%{input: [:text], output: :speech, mode: :sync}] = OpenAI.Speech.supported_modalities()
    end

    test "no key -> fast fail" do
      assert {:error, :missing_api_key} =
               OpenAI.Speech.generate_media(%Request{output: :speech, prompt: "hi"}, [])
    end

    test "returns raw audio bytes + mime" do
      stub_finch(fn -> ok200(@audio) end)

      assert {:ok, %{data: @audio, mime: "audio/mpeg", meta: %{}}} =
               OpenAI.Speech.generate_media(
                 %Request{output: :speech, prompt: "hello", api_key: "sk-x"},
                 []
               )
    end
  end

  describe "OpenAI.Transcription (STT, speech -> text)" do
    test "declares speech -> text sync" do
      assert [%{input: [:speech], output: :text, mode: :sync}] =
               OpenAI.Transcription.supported_modalities()
    end

    test "no key -> fast fail" do
      assert {:error, :missing_api_key} =
               OpenAI.Transcription.generate_media(%Request{output: :text, settings: %{audio: @audio}}, [])
    end

    test "no audio -> missing_audio" do
      assert {:error, :missing_audio} =
               OpenAI.Transcription.generate_media(%Request{output: :text, api_key: "sk-x"}, [])
    end

    test "returns the transcript text" do
      stub_finch(fn -> ok200(Jason.encode!(%{text: "hello world"})) end)

      assert {:ok, %{data: "hello world", mime: "text/plain"}} =
               OpenAI.Transcription.generate_media(
                 %Request{output: :text, api_key: "sk-x", settings: %{audio: @audio, filename: "a.mp3"}},
                 []
               )
    end
  end

  describe "LiteLLM.Media (proxy dispatcher)" do
    test "declares image/speech/music/sfx/video + transcription" do
      outs = LiteLLM.Media.supported_modalities() |> Enum.map(& &1.output) |> Enum.sort()
      assert outs == Enum.sort([:image, :speech, :music, :sfx, :video, :text])
    end

    test "dispatches image -> b64 decode" do
      stub_finch(fn -> ok200(Jason.encode!(%{data: [%{b64_json: @png_b64}]})) end)

      assert {:ok, %{data: @png}} =
               LiteLLM.Media.generate_media(%Request{output: :image, prompt: "cat", api_key: "k"}, [])
    end

    test "music without a configured endpoint -> modality_not_configured" do
      assert {:error, {:modality_not_configured, :music}} =
               LiteLLM.Media.generate_media(%Request{output: :music, prompt: "jazz", api_key: "k"}, [])
    end

    test "music with a per-request endpoint dispatches" do
      stub_finch(fn -> ok200(Jason.encode!(%{data: [%{b64_json: @png_b64}]})) end)

      assert {:ok, %{data: @png}} =
               LiteLLM.Media.generate_media(
                 %Request{output: :music, prompt: "jazz", api_key: "k", settings: %{endpoint: "/v1/audio/music"}},
                 []
               )
    end
  end

  describe "Suno (async music/sfx)" do
    test "declares text -> music + sfx async" do
      outs = Suno.supported_modalities() |> Enum.map(& &1.output) |> Enum.sort()
      assert outs == [:music, :sfx]
      assert Enum.all?(Suno.supported_modalities(), &(&1.mode == :async))
    end

    test "no key -> fast fail" do
      assert {:error, :missing_api_key} =
               Suno.generate_media(%Request{output: :music, prompt: "lofi"}, [])
    end

    test "submit returns an async Job with the task id" do
      stub_finch(fn -> ok200(Jason.encode!(%{data: %{taskId: "task-123"}})) end)

      assert {:ok, %GenAI.Media.Job{id: "task-123", provider: GenAI.Provider.Suno, status: :pending}} =
               Suno.generate_media(%Request{output: :music, prompt: "lofi", api_key: "k"}, [])
    end
  end

  describe "GenAI.generate_media routing (configured registry)" do
    test "image routes to OpenAI.Image" do
      stub_finch(fn -> ok200(Jason.encode!(%{data: [%{b64_json: @png_b64}]})) end)
      assert {:ok, %{data: @png}} = GenAI.generate_media(%Request{output: :image, prompt: "x", api_key: "k"})
    end

    test "speech routes to OpenAI.Speech" do
      stub_finch(fn -> ok200(@audio) end)
      assert {:ok, %{data: @audio}} = GenAI.generate_media(%Request{output: :speech, prompt: "x", api_key: "k"})
    end

    test "music routes to Suno (async)" do
      stub_finch(fn -> ok200(Jason.encode!(%{data: %{taskId: "t1"}})) end)
      assert {:ok, %GenAI.Media.Job{provider: GenAI.Provider.Suno}} =
               GenAI.generate_media(%Request{output: :music, prompt: "x", api_key: "k"})
    end

    test "transcription routes via the :speech input hint to OpenAI.Transcription" do
      stub_finch(fn -> ok200(Jason.encode!(%{text: "hi"})) end)

      assert {:ok, %{data: "hi"}} =
               GenAI.generate_media(%Request{
                 output: :text,
                 input: [:speech],
                 api_key: "k",
                 settings: %{audio: @audio}
               })
    end
  end
end
