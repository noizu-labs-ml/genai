defmodule GenAI.Provider.Groq.Models do
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

  def gpt_oss_120b(), do: model("openai/gpt-oss-120b")
  def gpt_oss_20b(), do: model("openai/gpt-oss-20b")

  def llama3_1_8b(), do: model("llama-3.1-8b-instant")
  def llama3_3_70b(), do: model("llama-3.3-70b-versatile")

  def llama4_maverick(), do: model("meta-llama/llama-4-maverick-17b-128e-instruct")
  def llama4_scout(), do: model("meta-llama/llama-4-scout-17b-16e-instruct")

  def llama_guard_4_12b(), do: model("meta-llama/llama-guard-4-12b")

  def qwen_3_32b(), do: model("qwen/qwen-3-32b")

  def whisper_large_v3(), do: model("whisper-large-v3")
  def whisper_large_v3_turbo(), do: model("whisper-large-v3-turbo")
end
