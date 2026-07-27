defmodule GenAI.Examples.OpenAIVoiceChatCLI do
  @moduledoc false

  alias GenAI.Media.Request

  @default_model "gpt-audio-1.5"
  @default_voice "alloy"
  @default_format "wav"
  @default_record_seconds 5
  @default_instructions "You are a concise voice assistant. Reply naturally and keep answers short."

  def main(args) do
    if "--help" in args or "-h" in args do
      print_help()
    else
      Application.ensure_all_started(:genai)

      state = %{
        model: env("GENAI_VOICE_MODEL", @default_model),
        voice: env("GENAI_VOICE", @default_voice),
        format: env("GENAI_AUDIO_FORMAT", @default_format),
        record_seconds: env_int("GENAI_RECORD_SECONDS", @default_record_seconds),
        instructions: env("GENAI_VOICE_INSTRUCTIONS", @default_instructions)
      }

      print_intro(state)
      loop(state)
    end
  end

  defp loop(state) do
    case IO.gets("\n[t]ext, [r]ecord, [f]ile, [q]uit> ") do
      nil ->
        :ok

      input ->
        input
        |> String.trim()
        |> String.downcase()
        |> handle_command(state)
    end
  end

  defp handle_command(command, _state) when command in ["q", "quit", "exit"], do: :ok

  defp handle_command(command, state) when command in ["t", "text", ""] do
    case IO.gets("you> ") do
      nil ->
        :ok

      prompt ->
        prompt = String.trim(prompt)

        if prompt == "" do
          loop(state)
        else
          prompt
          |> text_request(state)
          |> run_turn(state)

          loop(state)
        end
    end
  end

  defp handle_command(command, state) when command in ["r", "record"] do
    case record_audio(state.record_seconds) do
      {:ok, path} ->
        audio = File.read!(path)

        %Request{
          provider: GenAI.Provider.OpenAI.Audio,
          model: state.model,
          output: :speech,
          input: [:speech],
          prompt: "Respond to the user's spoken message.",
          settings: Map.merge(audio_settings(state), %{audio: audio, input_format: "wav"})
        }
        |> run_turn(state)

      {:error, reason} ->
        IO.puts("recording unavailable: #{inspect(reason)}")
        IO.puts("Install SoX `rec`, ffmpeg, or arecord, or use text mode.")
    end

    loop(state)
  end

  defp handle_command(command, state) when command in ["f", "file", "audio"] do
    case IO.gets("audio path> ") do
      nil ->
        :ok

      path ->
        path
        |> String.trim()
        |> audio_file_request(state)
        |> case do
          {:ok, request} ->
            run_turn(request, state)
            loop(state)

          {:error, reason} ->
            IO.puts("audio file unavailable: #{inspect(reason)}")
            loop(state)
        end
    end
  end

  defp handle_command(_, state) do
    IO.puts("Use t, r, f, or q.")
    loop(state)
  end

  defp text_request(prompt, state) do
    %Request{
      provider: GenAI.Provider.OpenAI.Audio,
      model: state.model,
      output: :speech,
      prompt: prompt,
      settings: audio_settings(state)
    }
  end

  defp audio_settings(state) do
    %{
      voice: state.voice,
      format: state.format,
      instructions: state.instructions
    }
  end

  defp audio_file_request("", _state), do: {:error, :missing_path}

  defp audio_file_request(path, state) do
    if File.exists?(path) do
      audio = File.read!(path)

      {:ok,
       %Request{
         provider: GenAI.Provider.OpenAI.Audio,
         model: state.model,
         output: :speech,
         input: [:speech],
         prompt: "Respond to the user's spoken message.",
         settings:
           Map.merge(audio_settings(state), %{
             audio: audio,
             input_format: audio_extension(path)
           })
       }}
    else
      {:error, {:not_found, path}}
    end
  end

  defp run_turn(%Request{} = request, state) do
    case GenAI.generate_media(request) do
      {:ok, %{data: audio, mime: mime, meta: meta}} ->
        meta
        |> assistant_text()
        |> case do
          nil -> :ok
          text -> IO.puts("assistant> #{text}")
        end

        {:ok, path} = write_audio(audio, extension_for(mime, state.format))
        IO.puts("audio> #{path}")
        play_audio(path)

      {:error, reason} ->
        IO.puts("openai error> #{inspect(reason)}")
    end
  end

  defp record_audio(seconds) do
    path = temp_file("genai-openai-input", "wav")

    with {:ok, {command, args}} <- recorder(path, seconds),
         {_, 0} <- System.cmd(command, args, stderr_to_stdout: true) do
      {:ok, path}
    else
      {:error, reason} -> {:error, reason}
      {output, status} -> {:error, {:record_failed, status, output}}
    end
  end

  defp recorder(path, seconds) do
    cond do
      command = System.find_executable("rec") ->
        {:ok,
         {command,
          ["-q", path, "rate", "24000", "channels", "1", "trim", "0", to_string(seconds)]}}

      command = System.find_executable("ffmpeg") ->
        {:ok,
         {command,
          [
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-f",
            ffmpeg_input_format(),
            "-i",
            ffmpeg_input_device(),
            "-t",
            to_string(seconds),
            "-ac",
            "1",
            "-ar",
            "24000",
            path
          ]}}

      command = System.find_executable("arecord") ->
        {:ok,
         {command,
          ["-q", "-d", to_string(seconds), "-f", "S16_LE", "-r", "24000", "-c", "1", path]}}

      true ->
        {:error, :no_recorder_command}
    end
  end

  defp play_audio(path) do
    case player(path) do
      {:ok, {command, args}} ->
        case System.cmd(command, args, stderr_to_stdout: true) do
          {_, 0} -> :ok
          {output, status} -> IO.puts("playback failed #{status}: #{String.trim(output)}")
        end

      {:error, reason} ->
        IO.puts("playback unavailable: #{inspect(reason)}")
    end
  end

  defp player(path) do
    cond do
      command = System.find_executable("afplay") ->
        {:ok, {command, [path]}}

      command = System.find_executable("ffplay") ->
        {:ok, {command, ["-nodisp", "-autoexit", "-loglevel", "error", path]}}

      command = System.find_executable("aplay") ->
        {:ok, {command, ["-q", path]}}

      true ->
        {:error, :no_player_command}
    end
  end

  defp write_audio(audio, extension) do
    path = temp_file("genai-openai-output", extension)
    File.write!(path, audio)
    {:ok, path}
  end

  defp temp_file(prefix, extension) do
    unique = System.unique_integer([:positive])
    Path.join(System.tmp_dir!(), "#{prefix}-#{unique}.#{extension}")
  end

  defp extension_for("audio/mpeg", _default), do: "mp3"
  defp extension_for("audio/opus", _default), do: "opus"
  defp extension_for("audio/aac", _default), do: "aac"
  defp extension_for("audio/flac", _default), do: "flac"
  defp extension_for("audio/wav", _default), do: "wav"
  defp extension_for("audio/pcm", _default), do: "pcm"
  defp extension_for(_, default), do: default

  defp audio_extension(path) do
    path
    |> Path.extname()
    |> String.trim_leading(".")
    |> case do
      "" -> "wav"
      extension -> extension
    end
  end

  defp assistant_text(%{text: text}) when is_binary(text) and text != "", do: text
  defp assistant_text(%{transcript: text}) when is_binary(text) and text != "", do: text
  defp assistant_text(_), do: nil

  defp ffmpeg_input_format do
    env("GENAI_FFMPEG_INPUT_FORMAT", default_ffmpeg_input_format())
  end

  defp ffmpeg_input_device do
    env("GENAI_FFMPEG_INPUT", default_ffmpeg_input_device())
  end

  defp default_ffmpeg_input_format do
    case :os.type() do
      {:unix, :darwin} -> "avfoundation"
      _ -> "pulse"
    end
  end

  defp default_ffmpeg_input_device do
    case :os.type() do
      {:unix, :darwin} -> ":0"
      _ -> "default"
    end
  end

  defp env(name, default) do
    case System.get_env(name) do
      nil -> default
      "" -> default
      value -> value
    end
  end

  defp env_int(name, default) do
    name
    |> env(to_string(default))
    |> Integer.parse()
    |> case do
      {value, ""} when value > 0 -> value
      _ -> default
    end
  end

  defp print_intro(state) do
    IO.puts("""
    OpenAI voice chat CLI
    model=#{state.model} voice=#{state.voice} format=#{state.format}

    Text mode always works.
    File mode sends an existing audio file as input.
    Record mode needs one recorder command: rec, ffmpeg, or arecord.
    Playback needs one player command: afplay, ffplay, or aplay.
    """)
  end

  defp print_help do
    IO.puts("""
    Usage:
      mix run examples/openai_voice_chat_cli.exs

    Required:
      OPENAI_API_KEY

    Optional:
      GENAI_VOICE_MODEL=gpt-audio-1.5
      GENAI_VOICE=alloy
      GENAI_AUDIO_FORMAT=wav
      GENAI_RECORD_SECONDS=5
      GENAI_VOICE_INSTRUCTIONS="You are a concise voice assistant."
      GENAI_FFMPEG_INPUT_FORMAT=avfoundation
      GENAI_FFMPEG_INPUT=:0

    Interactive commands:
      t/text   type a prompt and receive spoken audio
      r/record record a short microphone turn and receive spoken audio
      f/file   send an existing audio file and receive spoken audio
      q/quit   exit
    """)
  end
end

GenAI.Examples.OpenAIVoiceChatCLI.main(System.argv())
