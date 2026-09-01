defmodule GenAI.Provider.OpenAI.Models do
  @api_base "https://api.openai.com"
  import GenAI.InferenceProvider.Helpers

  # ⟦𓋩𓋺𓈜𓃀⟧ load_metadata :: auto-generated pointer for public function load_metadata
  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  # ⟦𓍖𓋱𓈏𓎓⟧ list :: auto-generated pointer for public function list
  def list(options \\ nil) do
    headers = GenAI.Provider.OpenAI.headers(options)
    call = api_call(:get, "#{@api_base}/v1/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{data: models, object: "list"} <- json do
        models =
          models
          |> Enum.map(&model_from_json/1)

        {:ok, models}
      else
        _ -> {:error, {:response, json}}
      end
    end
  end

  # ⟦𓀈𓀷𓅻𓅘⟧ model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.OpenAI,
      encoder: GenAI.Provider.OpenAI.Encoder
    }
  end

  # ⟦𓈜𓍯𓎤𓂋⟧ gpt_3_5_turbo :: auto-generated pointer for public function gpt_3_5_turbo
  def gpt_3_5_turbo(), do: model("gpt-3.5-turbo")

  # ⟦𓆞𓅺𓂐𓇻⟧ gpt_3_5_turbo_16k :: auto-generated pointer for public function gpt_3_5_turbo_16k
  def gpt_3_5_turbo_16k(), do: model("gpt-3.5-turbo-16k")

  # ⟦𓄵𓁣𓏚𓃚⟧ gpt_4 :: auto-generated pointer for public function gpt_4
  def gpt_4(), do: model("gpt-4")
  # ⟦𓃜𓀂𓈆𓈩⟧ gpt_4_turbo :: auto-generated pointer for public function gpt_4_turbo
  def gpt_4_turbo(), do: model("gpt-4-turbo")
  # ⟦𓇰𓁾𓈣𓌟⟧ gpt_4_vision :: auto-generated pointer for public function gpt_4_vision
  def gpt_4_vision(), do: model("gpt-4-vision")

  # ⟦𓎰𓎵𓈃𓎅⟧ gpt_5_6 :: auto-generated pointer for public function gpt_5_6
  def gpt_5_6(), do: model("gpt-5.6")
  # ⟦𓍮𓐔𓏏𓈖⟧ gpt_5_6_sol :: auto-generated pointer for public function gpt_5_6_sol
  def gpt_5_6_sol(), do: model("gpt-5.6-sol")

  # ⟦𓁺𓍚𓋗𓂜⟧ gpt_5_6_terra :: auto-generated pointer for public function gpt_5_6_terra
  def gpt_5_6_terra(), do: model("gpt-5.6-terra")
  # ⟦𓏺𓋴𓈌𓃗⟧ gpt_5_6_luna :: auto-generated pointer for public function gpt_5_6_luna
  def gpt_5_6_luna(), do: model("gpt-5.6-luna")
  # ⟦𓉚𓍫𓐞𓀄⟧ gpt_5_4 :: auto-generated pointer for public function gpt_5_4
  def gpt_5_4(), do: model("gpt-5.4")
  # ⟦𓐆𓎸𓊹𓆽⟧ gpt_5_4_pro :: auto-generated pointer for public function gpt_5_4_pro
  def gpt_5_4_pro(), do: model("gpt-5.4-pro")
  # ⟦𓂜𓌒𓎘𓈅⟧ gpt_5_2 :: auto-generated pointer for public function gpt_5_2
  def gpt_5_2(), do: model("gpt-5.2")
  # ⟦𓆲𓊢𓀯𓉸⟧ gpt_5 :: auto-generated pointer for public function gpt_5
  def gpt_5(), do: model("gpt-5")
  # ⟦𓉫𓈜𓐬𓈤⟧ gpt_5_mini :: auto-generated pointer for public function gpt_5_mini
  def gpt_5_mini(), do: model("gpt-5-mini")
  # ⟦𓏥𓊗𓄰𓍫⟧ gpt_5_nano :: auto-generated pointer for public function gpt_5_nano
  def gpt_5_nano(), do: model("gpt-5-nano")

  # ⟦𓄣𓎑𓂾𓇉⟧ gpt_4_1 :: auto-generated pointer for public function gpt_4_1
  def gpt_4_1(), do: model("gpt-4.1")
  # ⟦𓏩𓐁𓈼𓐜⟧ gpt_4_1_mini :: auto-generated pointer for public function gpt_4_1_mini
  def gpt_4_1_mini(), do: model("gpt-4.1-mini")
  # ⟦𓅠𓏗𓉥𓋇⟧ gpt_4_1_nano :: auto-generated pointer for public function gpt_4_1_nano
  def gpt_4_1_nano(), do: model("gpt-4.1-nano")

  # ⟦𓆆𓇹𓊷𓌪⟧ gpt_4o :: auto-generated pointer for public function gpt_4o
  def gpt_4o(), do: model("gpt-4o")
  # ⟦𓀱𓅐𓇟𓇠⟧ gpt_4o_audio :: auto-generated pointer for public function gpt_4o_audio
  def gpt_4o_audio(), do: model("gpt-4o-audio-preview")
  # ⟦𓀿𓈍𓁼𓁫⟧ gpt_4o_mini :: auto-generated pointer for public function gpt_4o_mini
  def gpt_4o_mini(), do: model("gpt-4o-mini")

  # ⟦𓆕𓂘𓆠𓎵⟧ gpt_4o_mini_audio :: auto-generated pointer for public function gpt_4o_mini_audio
  def gpt_4o_mini_audio(), do: model("gpt-4o-mini-audio-preview")

  # ⟦𓌰𓏕𓊨𓌑⟧ gpt_audio_1_5 :: auto-generated pointer for public function gpt_audio_1_5
  def gpt_audio_1_5(), do: model("gpt-audio-1.5")

  # ⟦𓋟𓆣𓄣𓁮⟧ gpt_4o_realtime :: auto-generated pointer for public function gpt_4o_realtime
  def gpt_4o_realtime(), do: model("gpt-4o-realtime-preview")

  # ⟦𓆮𓅹𓎥𓉑⟧ gpt_4o_mini_realtime :: auto-generated pointer for public function gpt_4o_mini_realtime
  def gpt_4o_mini_realtime(), do: model("gpt-4o-mini-realtime-preview")

  # ⟦𓋋𓋟𓐘𓁻⟧ gpt_realtime_2_1 :: auto-generated pointer for public function gpt_realtime_2_1
  def gpt_realtime_2_1(), do: model("gpt-realtime-2.1")

  # ⟦𓐙𓇽𓂭𓈚⟧ gpt_realtime_2_1_mini :: auto-generated pointer for public function gpt_realtime_2_1_mini
  def gpt_realtime_2_1_mini(), do: model("gpt-realtime-2.1-mini")

  # ⟦𓇞𓃘𓋯𓈒⟧ gpt_realtime_2 :: auto-generated pointer for public function gpt_realtime_2
  def gpt_realtime_2(), do: model("gpt-realtime-2")

  # ⟦𓅆𓆭𓂭𓏛⟧ gpt_realtime_translate :: auto-generated pointer for public function gpt_realtime_translate
  def gpt_realtime_translate(), do: model("gpt-realtime-translate")

  # ⟦𓍛𓁌𓐆𓂻⟧ gpt_realtime_1_5 :: auto-generated pointer for public function gpt_realtime_1_5
  def gpt_realtime_1_5(), do: model("gpt-realtime-1.5")

  # ⟦𓍧𓈹𓁷𓂝⟧ gpt_realtime_whisper :: auto-generated pointer for public function gpt_realtime_whisper
  def gpt_realtime_whisper(), do: model("gpt-realtime-whisper")

  # ⟦𓉌𓈖𓐡𓍻⟧ gpt_4o_mini_tts :: auto-generated pointer for public function gpt_4o_mini_tts
  def gpt_4o_mini_tts(), do: model("gpt-4o-mini-tts")

  # ⟦𓄺𓏒𓈳𓎦⟧ gtp_4o_mini_tts :: auto-generated pointer for public function gtp_4o_mini_tts
  def gtp_4o_mini_tts(), do: gpt_4o_mini_tts()

  # ⟦𓈍𓉂𓄝𓊩⟧ gpt_4o_transcribe :: auto-generated pointer for public function gpt_4o_transcribe
  def gpt_4o_transcribe(), do: model("gpt-4o-transcribe")

  # ⟦𓄁𓉶𓈦𓉎⟧ gpt_4o_mini_transcribe :: auto-generated pointer for public function gpt_4o_mini_transcribe
  def gpt_4o_mini_transcribe(), do: model("gpt-4o-mini-transcribe")

  # ⟦𓇂𓌗𓇝𓋵⟧ gpt_4o_transcribe_diarize :: auto-generated pointer for public function gpt_4o_transcribe_diarize
  def gpt_4o_transcribe_diarize(), do: model("gpt-4o-transcribe-diarize")

  # ⟦𓀪𓍶𓃏𓊢⟧ gpt_image_2 :: auto-generated pointer for public function gpt_image_2
  def gpt_image_2(), do: model("gpt-image-2")

  # ⟦𓇜𓆃𓎊𓂱⟧ chatgpt_4o :: auto-generated pointer for public function chatgpt_4o
  def chatgpt_4o(), do: model("chatgpt-4o-latest")

  # ⟦𓃞𓉦𓌮𓉤⟧ gpt_o1 :: auto-generated pointer for public function gpt_o1
  def gpt_o1(), do: model("o1")
  # ⟦𓂒𓎨𓐤𓄳⟧ gpt_o1_mini :: auto-generated pointer for public function gpt_o1_mini
  def gpt_o1_mini(), do: model("o1-mini")
  # ⟦𓋸𓍢𓄭𓍱⟧ gpt_o1_pro :: auto-generated pointer for public function gpt_o1_pro
  def gpt_o1_pro(), do: model("o1-pro")

  # ⟦𓈓𓎦𓇀𓈅⟧ gpt_o3 :: auto-generated pointer for public function gpt_o3
  def gpt_o3(), do: model("o3")
  # ⟦𓋆𓎕𓋖𓁉⟧ gpt_o3_mini :: auto-generated pointer for public function gpt_o3_mini
  def gpt_o3_mini(), do: model("o3-mini")

  # ⟦𓐖𓐚𓁶𓎤⟧ gpt_o4_mini :: auto-generated pointer for public function gpt_o4_mini
  def gpt_o4_mini(), do: model("o4-mini")

  # =============================================
  # Private Methods
  # =============================================

  # ------------------
  # Extract model from api request response.
  # @TODO move into Model module
  # ------------------
  defp model_metadata_provider do
    Application.get_env(:genai, :openai, [])[:metadata_provider] ||
      GenAI.ModelMetadata.DefaultProvider
  end

  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        model_metadata_provider(),
        GenAI.Provider.OpenAI,
        json[:id]
      )

    entry
  end
end
