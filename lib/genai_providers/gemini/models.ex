defmodule  GenAI.Provider.Gemini.Models do
  
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder
    }
  end
  
  #-------------------------
  # gemini_pro
  #-------------------------
  def gemini_pro(), do: gemini_pro_2_5_preview()
  def gemini_pro_1_0(), do: model("gemini-1.0-pro")
  def gemini_pro_1_5(), do: model("gemini-1.5-pro")
  def gemini_pro_2_5_preview(), do: model("gemini-2.5-pro-preview-03-25")
  
  #-------------------------
  # gemini_flash
  #-------------------------
  def gemini_flash(), do: gemini_flash_2_5_preview()
  def gemini_flash_1_5(), do: model("gemini-1.5-flash")
  def gemini_flash_1_5_8b(), do: model("gemini-1.5-flash-8b")
  def gemini_flash_2_0(), do: model("gemini-2.0-flash")
  def gemini_flash_2_0_image(), do: model("gemini-2.0-flash-exp-image-generation")
  def gemini_flash_2_0_lite(), do: model("gemini-2.0-flash-lite")
  def gemini_flash_2_5_preview(), do: model("gemini-2.5-flash-preview-04-17")
  

end