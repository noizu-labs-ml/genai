defmodule GenAI.Provider.Groq.Models do
  @moduledoc """
  Defines some common Groq models.
  """

  # <REMOVED UUID HERE> model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Groq,
      encoder: GenAI.Provider.Groq.Encoder
    }
  end

  # <REMOVED UUID HERE> gpt_oss_120b :: auto-generated pointer for public function gpt_oss_120b
  def gpt_oss_120b(), do: model("openai/gpt-oss-120b")
  # <REMOVED UUID HERE> gpt_oss_20b :: auto-generated pointer for public function gpt_oss_20b
  def gpt_oss_20b(), do: model("openai/gpt-oss-20b")

  # <REMOVED UUID HERE> llama3_1_8b :: auto-generated pointer for public function llama3_1_8b
  def llama3_1_8b(), do: model("llama-3.1-8b-instant")
  # <REMOVED UUID HERE> llama3_3_70b :: auto-generated pointer for public function llama3_3_70b
  def llama3_3_70b(), do: model("llama-3.3-70b-versatile")

  # <REMOVED UUID HERE> llama4_maverick :: auto-generated pointer for public function llama4_maverick
  def llama4_maverick(), do: model("meta-llama/llama-4-maverick-17b-128e-instruct")
  # <REMOVED UUID HERE> llama4_scout :: auto-generated pointer for public function llama4_scout
  def llama4_scout(), do: model("meta-llama/llama-4-scout-17b-16e-instruct")

  # <REMOVED UUID HERE> llama_guard_4_12b :: auto-generated pointer for public function llama_guard_4_12b
  def llama_guard_4_12b(), do: model("meta-llama/llama-guard-4-12b")

  # <REMOVED UUID HERE> qwen_3_32b :: auto-generated pointer for public function qwen_3_32b
  def qwen_3_32b(), do: model("qwen/qwen-3-32b")

  # <REMOVED UUID HERE> whisper_large_v3 :: auto-generated pointer for public function whisper_large_v3
  def whisper_large_v3(), do: model("whisper-large-v3")
  # <REMOVED UUID HERE> whisper_large_v3_turbo :: auto-generated pointer for public function whisper_large_v3_turbo
  def whisper_large_v3_turbo(), do: model("whisper-large-v3-turbo")
end
