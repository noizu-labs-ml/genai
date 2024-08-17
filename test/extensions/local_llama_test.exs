if Code.ensure_loaded?(GenAI.Provider.LocalLLama) do
  defmodule GenAI.LocalLLamaTest do
    use ExUnit.Case
    @moduletag provider: :local_llama
    @moduletag :live

    test "wip" do
      GenAI.Provider.LocalLLama.models()
    end

    test "inference" do
        thread = GenAI.chat()
                 |> GenAI.with_model(
                      GenAI.Provider.LocalLLama.Models.priv("local_llama/tiny_llama/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf")
                    )
                 |> GenAI.with_setting(:seed, 3)
                 |> GenAI.with_setting(:choices, 1)
                 |> GenAI.with_message(%GenAI.Message{role: :user, content: "Open the pod bay door HAL."})
                 |> GenAI.with_message(%GenAI.Message{role: :assistant, content: "I'm afraid I can't do that Dave"})
                 |> GenAI.with_message(%GenAI.Message{role: :user, content: "What is the movie \"2001: A Space Odyssey\" about?."})
        {:ok, sut} = GenAI.run(thread)

        assert sut.model =~ "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        assert sut.provider == GenAI.Provider.LocalLLama
        [choice_one] = sut.choices
        assert choice_one.message.content =~ "\"201: A Space Odyssey\" is a science fiction film directed by Stanley Kubrick"
        assert choice_one.finish_reason == :stop
        assert sut.usage == %GenAI.ChatCompletion.Usage{
                 prompt_tokens: 76,
                 total_tokens: 190,
                 completion_tokens: 114
               }
      end
  end
end
