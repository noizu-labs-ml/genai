
defmodule GenAI.DataLoader do
  defstruct [
    id: nil,
    source: nil,
    options: nil,
    agent: nil,
  ]

  def sample(_source, _options \\ nil) do
    # so for each loop we need to spawn an agent or something here.
    # todo return a struct extend loop macro to accept a struct rather than name.
    UUID.uuid5(:oid, "ABC") #return unique handle for worker
  end
  def take_one(_source, _options \\ nil) do
    %GenAI.Message{role: :user, content: "nyi"}
  end

end
