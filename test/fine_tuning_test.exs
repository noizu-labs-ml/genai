defmodule GenAI.FineTuningTest do
  use ExUnit.Case
  require GenAI
  @moduletag :beta

  test "proposed syntax" do
    data_loader = nil
    chat_thread = [
      %GenAI.Message{role: :system, content: "A System Prompt."},
      %GenAI.Message{role: :user, handle: "Call Back", content: "User Message."},
      %GenAI.Message{role: :assistant, content: "LLM Response"},
    ]
    fitness = :gpt_score
    sentinel = 0.05
    good_enough_system_prompt_sentinel = GenAI.EarlyStopThreshold.new(0.90)
    dynamic_system_prompt = %GenAI.DynamicMessage{
      role: :user,
      conventions: "npl@5",
      prompt: (
        GenAI.thread()
        |> GenAI.with_message(%GenAI.Message{role: :system, content: "A System Prompt."})
        |> GenAI.with_message(%GenAI.Message{role: :user, content: "Prepare a prompt instructing an llm to produce cat facts.."})
        )
    }

    # 1. append messages to tree.
    # 2. loop 25 times - generate a dynamic prompt in each loop
    # 3. add dynamic prompt message.
    # 4. perform 5 epochs per dynamic prompt
    # 5. loop 25 times - with data loader populated at start of each loop containing subset of available data + test cases (optional)
    # 6. in each of the 25 data loader loops inside the epoch tweak/massage prompt - knows fitness score of previous loops, if degraded performance undoes changes, applies different changes.
    # 7. in data loader loap grab next message from data set.
    # 8. generate fitness score of generated output - will call completion with prior constructed message queue.
    # 9. score epoch - compare fitness versus rubric/eval,  where this might be a ideal output value obtained from the DataLoader
    #     meaning we take all 25 loops here and compare their output scores to the evaluator score of our starting/initial prompt.
    #     and calculate harmonic averages etc f values whatever they're called.
    # 10. we exit the epoch loop early if score fails to go above sentinel/threshold improvement percent.
    # 11. we end prompt_search 25 early if we found a prompt that exceeded our acceptable score threshold
    # 12. we generate a report of all runs, the messages (delta logic here to avoid full copy each time), fitness, scores.
    GenAI.chat(:new)
    |> GenAI.with_messages(chat_thread) # 1.
    |> GenAI.loop(:prompt_search, 25) do  # 2.
         GenAI.with_message(dynamic_system_prompt, handle: :dynamic_system_prompt) # 3
         |> GenAI.loop(:epoch, 5) do # 4.
              GenAI.loop(GenAI.DataLoader.sample(data_loader), 25) do # 5.
                GenAI.tune_prompt(:dynamic_system_prompt) # 6. - this should probably outside of loop?
                |> GenAI.with_message(GenAI.DataLoader.take_one(data_loader)) # 7
                |> GenAI.fitness(fitness) # 8.
              end
              |> GenAI.score() # 9
              |> GenAI.early_stopping(sentinel)  # 10
            end
            |> GenAI.early_stopping(good_enough_system_prompt_sentinel) # 11
       end
      # @TODO - to perform grid we need a GenAI.grid method or syntax for specifying parameter grid.
      # GenAI.grid_search(name, params) do - we'll show this in a different test as the purpose is a little different.
    |> GenAI.with_model(GenAI.Provider.Groq.Models.llama3_8b())
    |> GenAI.with_setting(:temperature, 0.7)
    |> IO.inspect()
    |> GenAI.execute(:report) # 12
    |> IO.inspect()
  end
end
