
defmodule GenAI.Service.Model.MetaDataSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      %{
        id: GenAI.Service.Model.MetaDataServer,
        start: {GenAI.Service.Model.MetaDataServer, :start_link, [[]]},
        type: :worker,
        restart: :permanent
      }
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
