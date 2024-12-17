defmodule GenAI.UUID do
  @moduledoc """
  Wrapper around UUID generator to allow user to provide their own implementation.
  """
  def new() do
    UUID.uuid4()
  end
end