defmodule GenAI.Provider.LocalLLamaManager do
#
#  #========================
#  # Runtime Settings
#  #========================
#  def runtime_setting(setting, options \\ [])
#  def runtime_setting(setting, options) do
#    GenAI.Provider.LocalLLamaServer.runtime_setting(setting, options)
#  end
#
#  def subscribe(setting, options \\ []) do
#    GenAI.Provider.LocalLLamaServer.subscribe(setting, options)
#  end

  #========================
  # Methods
  #========================
  @doc """
  Retrieves a list of available Local models.
  This is done in worker process, and includes any loaded explicitly specified files plus priv folder scan results.
  @todo implement/can priv/gguf-models/ to get list of models.
  """
  def models(settings \\ [])
  def models(settings) do
    GenAI.Provider.LocalLLamaServer.get_models(settings)
  end

  def active_model(handle, settings \\ [])
  def active_model(handle, settings) do
    GenAI.Provider.LocalLLamaServer.get_model(handle, settings)
  end
end

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

defmodule GenAI.Provider.LocalLLamaServer do
  use GenServer
  alias Phoenix.PubSub
  @vsn 1.0

  defstruct [
    local_models: %{},
    vsn: @vsn
  ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
#    set_generation_key()
#    load_runtime_settings()
    {:ok, state}
  end

  def handle_call({:get_models, settings}, from, state) do
    do_get_models(state, from, settings)
  end

  def handle_call({:get_model, handle, settings}, from, state) do
    do_get_model(state, from, handle, settings)
  end

  @doc """

  """
  def get_models(settings \\ [])
  def get_models(settings) do
    GenServer.call(__MODULE__, {:get_models, settings})
  end

  defp do_get_models(state, from, settings)
  defp do_get_models(state, _, settings) do
    models = Enum.map(state.local_models, fn {_,model} -> model end)
    {:reply, {:ok, models}, state}
  end

  @doc """

  """
  def get_model(handle, settings \\ [])
  def get_model(handle, settings) do
    GenServer.call(__MODULE__, {:get_model, handle, settings})
  end

  defp do_get_model(state, from, handle, settings)
  defp do_get_model(state, _, handle, settings) do
    response = with {:ok, identifier} <- GenAI.ModelProtocol.identifier(handle) do
      if live_model = state.local_models[identifier] do
        {:ok, live_model}
      else
        # Load Model
        {:error, :not_found}
      end
    end
    {:reply, response, state}
  end



#
#  defp load_runtime_settings() do
#    # async gencast
#    :persistent_term.put(runtime_setting_key(:models), {:ok, []})
#  end
#
#  defp set_generation_key() do
#    :persistent_term.put({__MODULE__, :generation_key}, self())
#    :pending
#  end
#  defp get_generation_key() do
#    with :undefined <- :persistent_term.get({__MODULE__, :generation_key}, :undefined) do
#      {:error, :not_initialized}
#    else
#      x -> {:ok, x}
#    end
#  end
#
#  defp runtime_setting_key(setting) do
#    {__MODULE__, :runtime_setting, setting}
#  end
#
#  def subscribe(setting, options) do
#    # use syn to subscribe to setting on local node.
#    :ok
#  end
#
#  defp setting_update(setting, message) do
#    # todo use syn to broadcast message.
#    :ok
#  end
#
#  def request_setting(setting, options) do
#    # semaphore logic
#    if options[:blocking] do
#      {:pending, :subscribe_and_request}
#    else
#      {:pending, :request}
#    end
#  end
#
#  def runtime_setting(setting, options) do
#    case  :persistent_term.get(runtime_setting_key(name), :__genai_undefined__) do
#      :__genai_undefined__ -> request_setting(setting, options)
#      x = {:error, _} -> x
#      x = {:loading, _reference} ->
#        if options[:blocking] do
#          {:pending, :subscribe_and_wait}
#        else
#          :loading
#        end
#      x = {:ok, _} -> x
#      x -> throw "Invalid Internal State"
#    end
#  end


end
