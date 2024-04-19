defmodule GenAI.FineTuningTest do
  use ExUnit.Case
  require GenAI


  test "proposed syntax" do
    data_loader = nil
    chat_thread = []
    fitness = nil
    sentinel = nil
    good_enough_system_prompt_sentinel = nil
    dynamic_system_prompt = %GenAI.DynamicMessage{role: :user, content: "Tell me a random fact about cats using a tool call."}

    GenAI.chat(:new)
    |> GenAI.with_messages(chat_thread) # 1.
#    |> GenAI.loop(:prompt_search, 25) do  # 2.
#         GenAI.with_message(dynamic_system_prompt, handle: :dynamic_system_prompt) # 3
#         |> GenAI.loop(:epoch, 5) do # 4.
#              GenAI.loop(GenAI.DataLoader.sample(data_loader), 25) do # 5.
#              GenAI.Message.tune_prompt(:dynamic_system_prompt) # 6.
#              |> GenAI.with_message(GenAI.DataLoader.take_one(data_loader)) # 7
#              |> GenAI.fitness(fitness) # 8.
#            end
#         |> GenAI.score()
#         |> GenAI.early_stopping(sentinel)  #9
#       end
#    |> GenAI.early_stopping(good_enough_system_prompt_sentinel)
#  end
  |> GenAI.execute(:report) # 9
end

end
