defmodule GenAI.Provider.Gemini.Models do
  # <REMOVED UUID HERE> model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder
    }
  end

  # -------------------------
  # gemini_pro
  # -------------------------
  # <REMOVED UUID HERE> gemini_pro :: auto-generated pointer for public function gemini_pro
  def gemini_pro(), do: gemini_pro_3_1_preview()
  # <REMOVED UUID HERE> gemini_pro_3_1_preview :: auto-generated pointer for public function gemini_pro_3_1_preview
  def gemini_pro_3_1_preview(), do: model("gemini-3.1-pro-preview")
  # <REMOVED UUID HERE> gemini_pro_2_5 :: auto-generated pointer for public function gemini_pro_2_5
  def gemini_pro_2_5(), do: model("gemini-2.5-pro")
  # <REMOVED UUID HERE> gemini_pro_2_5_preview :: auto-generated pointer for public function gemini_pro_2_5_preview
  def gemini_pro_2_5_preview(), do: model("gemini-2.5-pro-preview-03-25")
  # <REMOVED UUID HERE> gemini_pro_1_5 :: auto-generated pointer for public function gemini_pro_1_5
  def gemini_pro_1_5(), do: model("gemini-1.5-pro")
  # <REMOVED UUID HERE> gemini_pro_1_0 :: auto-generated pointer for public function gemini_pro_1_0
  def gemini_pro_1_0(), do: model("gemini-1.0-pro")

  # -------------------------
  # gemini_flash
  # -------------------------
  # <REMOVED UUID HERE> gemini_flash :: auto-generated pointer for public function gemini_flash
  def gemini_flash(), do: gemini_flash_3_preview()
  # <REMOVED UUID HERE> gemini_flash_3_preview :: auto-generated pointer for public function gemini_flash_3_preview
  def gemini_flash_3_preview(), do: model("gemini-3-flash-preview")
  # <REMOVED UUID HERE> gemini_flash_2_5 :: auto-generated pointer for public function gemini_flash_2_5
  def gemini_flash_2_5(), do: model("gemini-2.5-flash")
  # <REMOVED UUID HERE> gemini_flash_2_5_lite :: auto-generated pointer for public function gemini_flash_2_5_lite
  def gemini_flash_2_5_lite(), do: model("gemini-2.5-flash-lite")
  # <REMOVED UUID HERE> gemini_flash_2_5_preview :: auto-generated pointer for public function gemini_flash_2_5_preview
  def gemini_flash_2_5_preview(), do: model("gemini-2.5-flash-preview-04-17")
  # <REMOVED UUID HERE> gemini_flash_2_0 :: auto-generated pointer for public function gemini_flash_2_0
  def gemini_flash_2_0(), do: model("gemini-2.0-flash")
  # <REMOVED UUID HERE> gemini_flash_2_0_image :: auto-generated pointer for public function gemini_flash_2_0_image
  def gemini_flash_2_0_image(), do: model("gemini-2.0-flash-exp-image-generation")
  # <REMOVED UUID HERE> gemini_flash_2_0_lite :: auto-generated pointer for public function gemini_flash_2_0_lite
  def gemini_flash_2_0_lite(), do: model("gemini-2.0-flash-lite")
  # <REMOVED UUID HERE> gemini_flash_1_5 :: auto-generated pointer for public function gemini_flash_1_5
  def gemini_flash_1_5(), do: model("gemini-1.5-flash")
  # <REMOVED UUID HERE> gemini_flash_1_5_8b :: auto-generated pointer for public function gemini_flash_1_5_8b
  def gemini_flash_1_5_8b(), do: model("gemini-1.5-flash-8b")
end
