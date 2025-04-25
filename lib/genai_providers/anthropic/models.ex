defmodule  GenAI.Provider.Anthropic.Models do
  @moduledoc """
  Defines some common Anthropic models.
  """
  def llama3_8b() do
    %GenAI.Model{
      model: "llama3-8b-8192",
      provider: GenAI.Provider.Anthropic
    }
  end
  
  def mixtral_8x7b() do
    %GenAI.Model{
      model: "mixtral-8x7b-32768",
      provider: GenAI.Provider.Anthropic
    }
  end
  
  def gemma_7b_it() do
    %GenAI.Model{
      model: "gemma-7b-it",
      provider: GenAI.Provider.Anthropic
    }
  end

end