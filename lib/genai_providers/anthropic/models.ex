defmodule GenAI.Provider.Anthropic.Models do
  @moduledoc """
  Defines some common Anthropic models.
  """

  # ⟦𓏤𓋐𓎞𓏽⟧ model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Anthropic,
      encoder: GenAI.Provider.Anthropic.Encoder
    }
  end

  # ---------------------------
  # claude_opus
  # ---------------------------
  # ⟦𓂔𓍮𓆭𓆓⟧ claude_opus :: auto-generated pointer for public function claude_opus
  def claude_opus(), do: claude_opus_4_6()
  # ⟦𓆜𓐎𓏪𓂳⟧ claude_opus_4_6 :: auto-generated pointer for public function claude_opus_4_6
  def claude_opus_4_6(), do: model("claude-opus-4-6")
  # ⟦𓉇𓈲𓇡𓋂⟧ claude_opus_4_5 :: auto-generated pointer for public function claude_opus_4_5
  def claude_opus_4_5(), do: model("claude-opus-4-5")
  # ⟦𓈡𓂺𓍢𓅳⟧ claude_opus_3 :: auto-generated pointer for public function claude_opus_3
  def claude_opus_3(), do: model("claude-3-opus-20240229")

  # ---------------------------
  # claude_sonnet
  # ---------------------------
  # ⟦𓊐𓌔𓆇𓏹⟧ claude_sonnet :: auto-generated pointer for public function claude_sonnet
  def claude_sonnet(), do: claude_sonnet_4_6()
  # ⟦𓍐𓌌𓆴𓏁⟧ claude_sonnet_4_6 :: auto-generated pointer for public function claude_sonnet_4_6
  def claude_sonnet_4_6(), do: model("claude-sonnet-4-6")
  # ⟦𓃥𓅛𓌔𓎍⟧ claude_sonnet_4_5 :: auto-generated pointer for public function claude_sonnet_4_5
  def claude_sonnet_4_5(), do: model("claude-sonnet-4-5")
  # ⟦𓆼𓐅𓆂𓂬⟧ claude_sonnet_4 :: auto-generated pointer for public function claude_sonnet_4
  def claude_sonnet_4(), do: model("claude-sonnet-4-20250514")
  # ⟦𓐛𓏔𓆌𓆫⟧ claude_sonnet_3_7 :: auto-generated pointer for public function claude_sonnet_3_7
  def claude_sonnet_3_7(), do: model("claude-3-7-sonnet-20250219")
  # ⟦𓈡𓃞𓅪𓍏⟧ claude_sonnet_3_5 :: auto-generated pointer for public function claude_sonnet_3_5
  def claude_sonnet_3_5(), do: model("claude-3-5-sonnet-20240620")
  # ⟦𓈩𓐩𓁠𓇍⟧ claude_sonnet_3_5b :: auto-generated pointer for public function claude_sonnet_3_5b
  def claude_sonnet_3_5b(), do: model("claude-3-5-sonnet-20241022")

  # ---------------------------
  # claude_haiku
  # ---------------------------
  # ⟦𓎳𓎬𓈊𓍄⟧ claude_haiku :: auto-generated pointer for public function claude_haiku
  def claude_haiku(), do: claude_haiku_4_5()
  # ⟦𓇿𓀓𓉙𓊈⟧ claude_haiku_4_5 :: auto-generated pointer for public function claude_haiku_4_5
  def claude_haiku_4_5(), do: model("claude-haiku-4-5")
  # ⟦𓆪𓎤𓋰𓏓⟧ claude_haiku_3_5 :: auto-generated pointer for public function claude_haiku_3_5
  def claude_haiku_3_5(), do: model("claude-3-5-haiku-20241022")
  # ⟦𓀞𓏽𓐌𓈑⟧ claude_haiku_3 :: auto-generated pointer for public function claude_haiku_3
  def claude_haiku_3(), do: model("claude-3-haiku-20240307")
end
