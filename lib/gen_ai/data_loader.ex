
defmodule GenAI.DataLoader do
  def sample(_, _ \\ nil) do
    :ok
  end
  def take_one(_, _ \\ nil) do
    %GenAI.Message{role: :user, content: "nyi"}
  end

end
