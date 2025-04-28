defmodule  GenAI.Provider.Groq.Models do
  @moduledoc """
  Defines some common Groq models.
  """
  
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Groq,
      encoder: GenAI.Provider.Groq.Encoder
    }
  end
  
  def qwq_32b(), do: model("qwen-qwq-32b")
  def deepseek_r1_70b(), do: model("deepseek-r1-distill-llama-70b")
  def gemma_2_instruct(), do: model("gemma2-9b-it")
  def compound_beta(), do: model("compound-beta")
  def compound_beta_mini(), do: model("compound-beta-mini")
  def llama3_1_8b(), do: model("llama-3.1-8b-instant")
  def llama3_3_70b(), do: model("llama-3.3-70b-versatile")
  def llama3_70b(), do: model("llama3-70b-8192")
  def llama3_8b(), do: model("llama3-8b-8192")
  
  def llama4_maverick(), do: model("meta-llama/llama-4-maverick-17b-128e-instruct")
  def llama4_scout(), do: model("meta-llama/llama-4-scout-17b-16e-instruct")
  
  def mistral_saba_24b(), do: model("mistral-saba-24b")
  
end