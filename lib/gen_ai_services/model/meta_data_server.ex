defmodule GenAI.Service.Model.MetaDataServer do
  use GenServer
  @vsn 1.0

  defstruct [
    vsn: @vsn
  ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    IO.puts "STARTING METADATA SERVER"
    {:ok, state}
  end

  @impl true
  def handle_call(call, from, state)
   def handle_call(call, _, state) do
     Logger.warn(
       """
       [#{__MODULE__}] unsupported call: #{inspect(call)}
       """)
    {:reply, :unsupported, state}
  end
end
