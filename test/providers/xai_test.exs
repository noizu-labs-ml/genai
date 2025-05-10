defmodule GenAI.Provider.XAITest do
  use ExUnit.Case
  import GenAI.Test.Support.Common
  @moduletag provider: :xai
  
  
  def priv() do
    :code.priv_dir(:genai) |> List.to_string()
  end
  
  describe "XAI Provider" do
    
    @tag :live
    @tag :advanced
    @tag provider: :xai
    @tag thread: :session
    test "Advanced Context run - vnext session" do
      thread = GenAI.chat(:session)
               |> GenAI.with_model(GenAI.Provider.XAI.Models.grok_3_mini())
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL"})
               |> GenAI.with_message(%GenAI.Message{role: :assistant, content: "I'm afraid I can't do that Dave"})
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "What is the movie \"2001: A Space Odyssey\" about and who directed it?"})
      {:ok, sut} = GenAI.run(thread)
      response = sut.choices |> hd()
      assert response.message.content =~ "Stanley Kubrick"
      IO.inspect(response)
    end
    
  end

end
