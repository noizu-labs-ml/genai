defmodule GenAI.Thread.State do
  @vsn 1.0

  defstruct [
    id: nil,
    flow: nil,
    vsn: @vsn
  ]

  def update(state, update) do
    # todo merge change list
    {:ok, update}
  end

  def clone(state) do
    # todo merge change list
    {:ok, state}
  end



end


defmodule GenAI.Thread.Manager do
  def start(_) do
    {:ok, 1234}
  end

  def emit(start, event) do
    :ok
  end

  def yield(state, _yield_for) do
    t = Task.async(
      fn ->
        Process.sleep(1000)
        {:ok, state}
      end
    )
    {:ok, t}
  end

end