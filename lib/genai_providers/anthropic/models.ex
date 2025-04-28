defmodule  GenAI.Provider.Anthropic.Models do
  @moduledoc """
  Defines some common Anthropic models.
  """
  
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Anthropic,
      encoder: GenAI.Provider.Anthropic.Encoder
    }
  end
  
  
  #---------------------------
  # claude_opus
  #---------------------------
  def claude_opus(), do: claude_opus_3()
  def claude_opus_3(), do: model("claude-3-opus-20240229")
  
  #---------------------------
  # claude_sonnet
  #---------------------------
  def claude_sonnet(), do: claude_sonnet_3_7()
  def claude_sonnet_3_7(), do: model("claude-3-7-sonnet-20250219")
  def claude_sonnet_3_5(), do: model("claude-3-5-sonnet-20240620")
  def claude_sonnet_3_5b(), do: model("claude-3-5-sonnet-20241022")
  
  #---------------------------
  # claude_haiku
  #---------------------------
  def claude_haiku(), do: claude_haiku_3_5()
  def claude_haiku_3_5(), do: model("claude-3-5-haiku-20241022")
  def claude_haiku_3(), do: model("claude-3-haiku-20240307")

end