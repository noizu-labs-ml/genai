defmodule GenAI.Provider.OllamaTest do
  use ExUnit.Case

  @moduletag provider: :ollama
  
  
  def priv() do
    :code.priv_dir(:genai) |> List.to_string()
  end
  
  describe "Ollama Provider" do
    
    @tag :live
    @tag :advanced
    @tag provider: :ollama
    @tag thread: :session
    test "Advanced Context run - vnext session" do
      thread = GenAI.chat(:session)
               |> GenAI.with_model(GenAI.Provider.Ollama.Models.model("llama3.2-vision:latest"))
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_setting(:stream, false)
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL"})
               |> GenAI.with_message(%GenAI.Message{role: :assistant, content: "I'm afraid I can't do that Dave"})
               |> GenAI.with_message(%GenAI.Message{role: :user, content: "What is the movie \"2001: a Space Odyssey\" about and who directed it?"})
      {:ok, sut} = GenAI.run(thread)
      response = sut.choices |> hd()
      assert response.message.content =~ "Stanley Kubrick" or response.message.content =~ "Kubrick"
    end
    
  end

end