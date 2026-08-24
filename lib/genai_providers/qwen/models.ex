defmodule GenAI.Provider.Qwen.Models do
  @moduledoc """
  Convenience constructors for Alibaba Cloud Model Studio (DashScope) Qwen models.

  Any model id the compatible-mode `/models` catalog returns can be wrapped with
  `model/1`. Named helpers cover the current commercial aliases (verified against
  DashScope international when a `QWEN_API_KEY` is available).
  """
  @model_metadata_provider Application.compile_env(:genai, :qwen)[:metadata_provider] ||
                             GenAI.ModelMetadata.DefaultProvider

  import GenAI.InferenceProvider.Helpers

  # ⟦𓄀𓆦𓈌𓏍⟧ load_metadata :: auto-generated pointer for public function load_metadata
  def load_metadata(options \\ nil)

  def load_metadata(_) do
    :ok
  end

  # TODO allow local meta data merge
  # ⟦𓅠𓍌𓈴𓐦⟧ list :: auto-generated pointer for public function list
  def list(options \\ nil) do
    headers = GenAI.Provider.Qwen.headers(options)
    call = api_call(:get, "#{GenAI.Provider.Qwen.base_url()}/models", headers)

    with {:ok, %Finch.Response{status: 200, body: body}} <- call,
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      with %{data: models, object: "list"} <- json do
        {:ok, Enum.map(models, &model_from_json/1)}
      else
        _ -> {:error, {:response, json}}
      end
    end
  end

  # ⟦𓆙𓍰𓉫𓅔⟧ model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Qwen,
      encoder: GenAI.Provider.Qwen.Encoder
    }
  end

  # LLM — live compatible-mode /models (2026-08-24), including Model Studio quota aliases.
  # ⟦𓈘𓋍𓌑𓍒⟧ qwen3_8_max :: auto-generated pointer for public function qwen3_8_max
  def qwen3_8_max(), do: model("qwen3.8-max")
  # ⟦𓊄𓍂𓅱𓁮⟧ qwen3_8_27b :: auto-generated pointer for public function qwen3_8_27b
  def qwen3_8_27b(), do: model("qwen3.8-27b")

  # ⟦𓆻𓅯𓏁𓅿⟧ qwen3_8_2_4t_a95b :: auto-generated pointer for public function qwen3_8_2_4t_a95b
  def qwen3_8_2_4t_a95b(), do: model("qwen3.8-2.4t-a95b")

  # ⟦𓋘𓍣𓃗𓃤⟧ qwen3_7_max :: auto-generated pointer for public function qwen3_7_max
  def qwen3_7_max(), do: model("qwen3.7-max")

  # ⟦𓀣𓆥𓁰𓂨⟧ qwen3_7_max_2026_06_08 :: auto-generated pointer for public function qwen3_7_max_2026_06_08
  def qwen3_7_max_2026_06_08(), do: model("qwen3.7-max-2026-06-08")
  # ⟦𓉙𓁉𓌥𓃂⟧ qwen3_7_plus :: auto-generated pointer for public function qwen3_7_plus
  def qwen3_7_plus(), do: model("qwen3.7-plus")

  # ⟦𓀟𓅃𓉫𓇞⟧ qwen3_7_plus_2026_05_26 :: auto-generated pointer for public function qwen3_7_plus_2026_05_26
  def qwen3_7_plus_2026_05_26(), do: model("qwen3.7-plus-2026-05-26")

  # ⟦𓏹𓉰𓌩𓂨⟧ qwen3_7_flash :: auto-generated pointer for public function qwen3_7_flash
  def qwen3_7_flash(), do: model("qwen3.7-flash")

  # ⟦𓎉𓁓𓀖𓀺⟧ qwen3_7_flash_2026_07_15 :: auto-generated pointer for public function qwen3_7_flash_2026_07_15
  def qwen3_7_flash_2026_07_15(), do: model("qwen3.7-flash-2026-07-15")

  # ⟦𓅚𓅷𓁿𓅂⟧ qwen3_max :: auto-generated pointer for public function qwen3_max
  def qwen3_max(), do: model("qwen3-max")
  # ⟦𓅭𓃇𓈁𓍇⟧ qwen_max :: auto-generated pointer for public function qwen_max
  def qwen_max(), do: model("qwen-max")
  # ⟦𓅄𓏁𓃹𓂺⟧ qwen_plus :: auto-generated pointer for public function qwen_plus
  def qwen_plus(), do: model("qwen-plus")
  # ⟦𓃶𓆐𓉜𓉈⟧ qwen_flash :: auto-generated pointer for public function qwen_flash
  def qwen_flash(), do: model("qwen-flash")
  # ⟦𓐣𓏛𓃶𓆙⟧ qwen_turbo :: auto-generated pointer for public function qwen_turbo
  def qwen_turbo(), do: model("qwen-turbo")

  # DashScope-hosted third-party chat (same compatible-mode catalog).
  # ⟦𓍭𓎞𓈭𓍗⟧ kimi_k3 :: auto-generated pointer for public function kimi_k3
  def kimi_k3(), do: model("kimi-k3")

  # ⟦𓃰𓇺𓊘𓌖⟧ kimi_k2_7_code :: auto-generated pointer for public function kimi_k2_7_code
  def kimi_k2_7_code(), do: model("kimi-k2.7-code")
  # ⟦𓌏𓀏𓋡𓊰⟧ glm_5_1 :: auto-generated pointer for public function glm_5_1
  def glm_5_1(), do: model("glm-5.1")
  # ⟦𓋸𓄵𓁬𓂠⟧ glm_5_2 :: auto-generated pointer for public function glm_5_2
  def glm_5_2(), do: model("glm-5.2")

  # ⟦𓃒𓉳𓌀𓎣⟧ deepseek_v4_flash_0731 :: auto-generated pointer for public function deepseek_v4_flash_0731
  def deepseek_v4_flash_0731(), do: model("deepseek-v4-flash-0731")

  # ⟦𓁛𓀮𓄖𓄵⟧ deepseek_v4_pro_0813 :: auto-generated pointer for public function deepseek_v4_pro_0813
  def deepseek_v4_pro_0813(), do: model("deepseek-v4-pro-0813")

  # Vision / coder
  # ⟦𓅭𓃇𓈁𓍈⟧ qwen3_coder_plus :: auto-generated pointer for public function qwen3_coder_plus
  def qwen3_coder_plus(), do: model("qwen3-coder-plus")

  # ⟦𓅄𓏁𓃹𓂻⟧ qwen3_vl_plus :: auto-generated pointer for public function qwen3_vl_plus
  def qwen3_vl_plus(), do: model("qwen3-vl-plus")

  # Embedding — OpenAI-compatible /v1/embeddings (qwen3.7-text-embedding is on /models).
  # ⟦𓄣𓎑𓂾𓇉⟧ qwen3_7_text_embedding :: auto-generated pointer for public function qwen3_7_text_embedding
  def qwen3_7_text_embedding(), do: model("qwen3.7-text-embedding")

  # ⟦𓎰𓎵𓈃𓎅⟧ text_embedding_v3 :: auto-generated pointer for public function text_embedding_v3
  def text_embedding_v3(), do: model("text-embedding-v3")

  # ⟦𓍮𓐔𓏏𓈖⟧ text_embedding_v4 :: auto-generated pointer for public function text_embedding_v4
  def text_embedding_v4(), do: model("text-embedding-v4")

  # Image generation ids present on compatible-mode /models (native image APIs, not chat).
  # ⟦𓁺𓍚𓋗𓂜⟧ qwen_image_3_0 :: auto-generated pointer for public function qwen_image_3_0
  def qwen_image_3_0(), do: model("qwen-image-3.0")

  # ⟦𓏺𓋴𓈌𓃗⟧ qwen_image_3_0_pro :: auto-generated pointer for public function qwen_image_3_0_pro
  def qwen_image_3_0_pro(), do: model("qwen-image-3.0-pro")

  # ⟦𓉚𓍫𓐞𓀄⟧ qwen_image_2_0_pro_2026_06_22 :: auto-generated pointer for public function qwen_image_2_0_pro_2026_06_22
  def qwen_image_2_0_pro_2026_06_22(), do: model("qwen-image-2.0-pro-2026-06-22")
  # ⟦𓐆𓎸𓊹𓆽⟧ wan2_7_image :: auto-generated pointer for public function wan2_7_image
  def wan2_7_image(), do: model("wan2.7-image")

  # Audio — Model Studio Audio tab (native catalog; subset also on compatible-mode).
  # ⟦𓂜𓌒𓎘𓈅⟧ qwen_audio_3_0_asr_flash :: auto-generated pointer for public function qwen_audio_3_0_asr_flash
  def qwen_audio_3_0_asr_flash(), do: model("qwen-audio-3.0-asr-flash")

  # ⟦𓉫𓈜𓐬𓈤⟧ qwen_audio_3_0_asr_flash_filetrans :: auto-generated pointer for public function qwen_audio_3_0_asr_flash_filetrans
  def qwen_audio_3_0_asr_flash_filetrans(), do: model("qwen-audio-3.0-asr-flash-filetrans")

  # ⟦𓏥𓊗𓄰𓍫⟧ qwen_audio_3_0_asr_flash_streaming :: auto-generated pointer for public function qwen_audio_3_0_asr_flash_streaming
  def qwen_audio_3_0_asr_flash_streaming(), do: model("qwen-audio-3.0-asr-flash-streaming")

  # ⟦𓄣𓎑𓂾𓇊⟧ qwen_audio_3_0_tts_flash :: auto-generated pointer for public function qwen_audio_3_0_tts_flash
  def qwen_audio_3_0_tts_flash(), do: model("qwen-audio-3.0-tts-flash")

  # ⟦𓎰𓎵𓈃𓎆⟧ qwen_audio_3_0_tts_plus :: auto-generated pointer for public function qwen_audio_3_0_tts_plus
  def qwen_audio_3_0_tts_plus(), do: model("qwen-audio-3.0-tts-plus")

  # Realtime voice chat (native catalog, Realtime-Chatting — not compatible-mode /models).
  # ⟦𓁺𓍚𓋗𓂝⟧ qwen_audio_3_0_realtime_flash :: auto-generated pointer for public function qwen_audio_3_0_realtime_flash
  def qwen_audio_3_0_realtime_flash(), do: model("qwen-audio-3.0-realtime-flash")

  # ⟦𓏺𓋴𓈌𓃘⟧ qwen_audio_3_0_realtime_plus :: auto-generated pointer for public function qwen_audio_3_0_realtime_plus
  def qwen_audio_3_0_realtime_plus(), do: model("qwen-audio-3.0-realtime-plus")

  # ⟦𓆲𓊢𓀯𓉸⟧ qwen3_tts_flash :: auto-generated pointer for public function qwen3_tts_flash
  def qwen3_tts_flash(), do: model("qwen3-tts-flash")

  # ⟦𓍮𓐔𓏏𓈗⟧ fun_asr_flash_2026_06_15 :: auto-generated pointer for public function fun_asr_flash_2026_06_15
  def fun_asr_flash_2026_06_15(), do: model("fun-asr-flash-2026-06-15")

  # =============================================
  # Private Methods
  # =============================================
  defp model_from_json(json) do
    {:ok, entry} =
      GenAI.ModelMetadata.ProviderBehaviour.get(
        @model_metadata_provider,
        GenAI.Provider.Qwen,
        json[:id]
      )

    entry
  end
end
