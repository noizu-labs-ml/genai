defmodule GenAI.Provider.LocalLLamaSupervisor do

  @doc """
  Retrieves a list of available Local models.
  This is done in worker process, and includes any loaded explicitly specified files plus priv folder scan results.
  @todo implement/can priv/gguf-models/ to get list of models.
  """
  def models(settings \\ nil)
  def models(_) do
      {:ok, []}
  end

end
