defmodule GenAI.Provider.DeepSeekTest do
  use ExUnit.Case
  import GenAI.Test.Support.Common
  @moduletag provider: :deepseek
  
  
  def priv() do
    :code.priv_dir(:genai) |> List.to_string()
  end
  
  describe "DeepSeek Provider" do
    
    @tag :live
    @tag :advanced
    @tag provider: :deepseek
    @tag thread: :session
    test "Advanced Context run - vnext session" do
      thread = GenAI.chat(:session)
               |> GenAI.with_model(GenAI.Provider.DeepSeek.Models.deepseek_reasoner())
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL"})
               |> GenAI.with_message(%GenAI.Message{role: :assistant, content: "I'm afraid I can't do that Dave"})
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "What is the movie \"2001: A Space Odyssey\" about and who directed it?"})
      {:ok, sut} = GenAI.run(thread)
      first_choice = sut.choices |> hd()
      [reasoning_content, text_content] = first_choice.message.content
      assert text_content.text =~ "Stanley Kubrick"
      IO.inspect(sut)
    end
    
  end

end
