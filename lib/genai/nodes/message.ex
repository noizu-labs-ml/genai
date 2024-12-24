#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Message do
  @vsn 1.0
  @moduledoc """
  Struct for representing a chat message.
  """

  use GenAI.Flow.NodeBehaviour
  alias GenAI.Flow.Types, as: T

  @derive GenAI.Flow.NodeProtocol
  defnode [
    role: nil,
    content: nil,
  ]
  defnodetype [
    role: any,
    content: any,
  ]

  def new(role, message) do
    id = UUID.uuid4()
    %__MODULE__{
      id: id,
      role: role,
      content: message
    }
  end

  def user(message) do
    new(:user, message)
  end

  def system(message) do
    new(:system, message)
  end

  def assistant(message) do
    new(:assistant, message)
  end
end


defimpl GenAI.MessageProtocol, for: GenAI.Message do
  def stub(_), do: :ok
end
