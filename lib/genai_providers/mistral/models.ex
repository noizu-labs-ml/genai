defmodule GenAI.Provider.Mistral.Models do
  @moduledoc """
  Defines some common Mistral models.
  """
  
  
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Mistral,
      encoder: GenAI.Provider.Mistral.Encoder
    }
  end
  
  #--------------------------
  #
  #--------------------------
  def mistral_small(), do: model("mistral-small-latest")
  
  #--------------------------
  #
  #--------------------------
  def mistral_medium(), do: model("mistral-medium-latest")
  
  #--------------------------
  #
  #--------------------------
  def mistral_large(), do: model("mistral-large-latest")
  
  
  #--------------------------
  #
  #--------------------------
  def codestral(), do: model("codestral-latest")
  
  #--------------------------
  #
  #--------------------------
  def pixstral(), do: model("pixtral-large-latest  ")
  
  #--------------------------
  #
  #--------------------------
  def mistral_saba(), do: model("mistral-saba-latest")
  
  #--------------------------
  #
  #--------------------------
  def ministral_3b(), do: model("ministral-3b-latest")
  
  def ministral_8b(), do: model("ministral-87b-latest")


end
