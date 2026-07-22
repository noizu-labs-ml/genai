defmodule GenAI.Provider.Gemini.Models do
  # ⟦𓃨𓂍𓀇𓈓⟧ model :: auto-generated pointer for public function model
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
  # ⟦𓀳𓎂𓊌𓈬⟧ gemini_pro :: auto-generated pointer for public function gemini_pro
  def gemini_pro(), do: gemini_pro_3_1_preview()
  # ⟦𓎨𓋵𓎽𓆹⟧ gemini_pro_3_1_preview :: auto-generated pointer for public function gemini_pro_3_1_preview
  def gemini_pro_3_1_preview(), do: model("gemini-3.1-pro-preview")
  # ⟦𓈷𓃓𓐇𓇽⟧ gemini_pro_2_5 :: auto-generated pointer for public function gemini_pro_2_5
  def gemini_pro_2_5(), do: model("gemini-2.5-pro")
  # ⟦𓁒𓍷𓇺𓅌⟧ gemini_pro_2_5_preview :: auto-generated pointer for public function gemini_pro_2_5_preview
  def gemini_pro_2_5_preview(), do: model("gemini-2.5-pro-preview-03-25")
  # ⟦𓏜𓌁𓇌𓎡⟧ gemini_pro_1_5 :: auto-generated pointer for public function gemini_pro_1_5
  def gemini_pro_1_5(), do: model("gemini-1.5-pro")
  # ⟦𓏯𓆧𓉩𓇂⟧ gemini_pro_1_0 :: auto-generated pointer for public function gemini_pro_1_0
  def gemini_pro_1_0(), do: model("gemini-1.0-pro")

  # -------------------------
  # gemini_flash
  # -------------------------
  # ⟦𓊦𓐮𓂋𓇻⟧ gemini_flash :: auto-generated pointer for public function gemini_flash
  def gemini_flash(), do: gemini_flash_3_preview()
  # ⟦𓐤𓏧𓍚𓄴⟧ gemini_flash_3_preview :: auto-generated pointer for public function gemini_flash_3_preview
  def gemini_flash_3_preview(), do: model("gemini-3-flash-preview")
  # ⟦𓋫𓅠𓐭𓍉⟧ gemini_flash_2_5 :: auto-generated pointer for public function gemini_flash_2_5
  def gemini_flash_2_5(), do: model("gemini-2.5-flash")
  # ⟦𓀿𓅌𓋬𓌦⟧ gemini_flash_2_5_lite :: auto-generated pointer for public function gemini_flash_2_5_lite
  def gemini_flash_2_5_lite(), do: model("gemini-2.5-flash-lite")
  # ⟦𓀋𓐁𓆖𓈁⟧ gemini_flash_2_5_preview :: auto-generated pointer for public function gemini_flash_2_5_preview
  def gemini_flash_2_5_preview(), do: model("gemini-2.5-flash-preview-04-17")
  # ⟦𓏊𓍜𓃶𓏎⟧ gemini_flash_2_0 :: auto-generated pointer for public function gemini_flash_2_0
  def gemini_flash_2_0(), do: model("gemini-2.0-flash")
  # ⟦𓀝𓉯𓍤𓋄⟧ gemini_flash_2_0_image :: auto-generated pointer for public function gemini_flash_2_0_image
  def gemini_flash_2_0_image(), do: model("gemini-2.0-flash-exp-image-generation")
  # ⟦𓎢𓄪𓏄𓁴⟧ gemini_flash_2_0_lite :: auto-generated pointer for public function gemini_flash_2_0_lite
  def gemini_flash_2_0_lite(), do: model("gemini-2.0-flash-lite")
  # ⟦𓈬𓈇𓈊𓏿⟧ gemini_flash_1_5 :: auto-generated pointer for public function gemini_flash_1_5
  def gemini_flash_1_5(), do: model("gemini-1.5-flash")
  # ⟦𓌭𓃷𓎐𓊞⟧ gemini_flash_1_5_8b :: auto-generated pointer for public function gemini_flash_1_5_8b
  def gemini_flash_1_5_8b(), do: model("gemini-1.5-flash-8b")
end
