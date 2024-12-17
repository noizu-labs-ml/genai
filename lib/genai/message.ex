defmodule GenAI.Message do
  @vsn 1.0

  defstruct [
    vsn: @vsn
  ]

  def new(role, message) do
    %__MODULE__{}
  end

  def user(message) do
    %__MODULE__{}
  end

  def system(message) do
    %__MODULE__{}
  end

  def assistant(message) do
    %__MODULE__{}
  end

end