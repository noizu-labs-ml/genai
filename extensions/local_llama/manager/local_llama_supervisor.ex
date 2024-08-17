
defmodule GenAI.Provider.LocalLLamaSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      %{
        id: GenAI.Provider.LocalLLamaServer,
        start: {GenAI.Provider.LocalLLamaServer, :start_link, [[]]},
        type: :worker,
        restart: :permanent
      }
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
