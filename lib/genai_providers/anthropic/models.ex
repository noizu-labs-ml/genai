defmodule  GenAI.Provider.Anthropic.Models do
  @moduledoc """
  Defines some common Anthropic models.
  """


  def claude_opus() do
    %GenAI.Model{
      model: "claude-3-opus-20240229",
      provider: GenAI.Provider.Anthropic
    }
  end


  def claude_sonnet() do
    %GenAI.Model{
      model: "claude-3-sonnet-20240229",
      provider: GenAI.Provider.Anthropic
    }
  end

  def claude_sonnet_3_5() do
    %GenAI.Model{
      model: "claude-3-5-sonnet-20240620",
      provider: GenAI.Provider.Anthropic
    }
  end

  def claude_haiku() do
    %GenAI.Model{
      model: "claude-3-haiku-20240307",
      provider: GenAI.Provider.Anthropic
    }
  end

end