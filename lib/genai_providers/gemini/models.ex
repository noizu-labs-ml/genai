defmodule  GenAI.Provider.Gemini.Models do
  
  def model(name) do
    %GenAI.Model{
      model: "gemini-pro",
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder
    }
  end
  
  def gemini_pro() do
    %GenAI.Model{
      model: "gemini-pro",
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder
    }
  end
  
  def gemini_pro_1_0() do
    %GenAI.Model{
      model: "gemini-1.0-pro",
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder
    }
  end
  
  def gemini_pro_1_5() do
    %GenAI.Model{
      model: "gemini-1.5-pro",
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder
    }
  end
  
  def gemini_flash_1_5() do
    %GenAI.Model{
      model: "gemini-1.5-flash",
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder
    }
  end
  
  def gemini_pro_vision() do
    %GenAI.Model{
      model: "gemini-pro-vision",
      provider: GenAI.Provider.Gemini,
      encoder: GenAI.Provider.Gemini.Encoder
    }
  end

end