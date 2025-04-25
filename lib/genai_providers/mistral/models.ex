defmodule GenAI.Provider.Mistral.Models do
  @moduledoc """
  Defines some common Mistral models.
  """
  def mistral_small() do
    %GenAI.Model{
      model: "mistral-small-latest",
      provider: GenAI.Provider.Mistral
    }
  end
  
  def mistral_medium() do
    %GenAI.Model{
      model: "mistral-medium-latest",
      provider: GenAI.Provider.Mistral
    }
  end
  
  def mistral_large() do
    %GenAI.Model{
      model: "mistral-large-latest",
      provider: GenAI.Provider.Mistral
    }
  end
end