defmodule GenAI.Message do
  @vsn 1.0
  @moduledoc """
  Struct for representing a chat message.
  """

  defstruct [
    role: nil,
    content: nil,
    vsn: @vsn
  ]

  @type t :: %__MODULE__{
               role: :user | :assistant | :system | any,
               content: String.t() | list(),
               vsn: float
             }


  def new(role, message) do
    %__MODULE__{
      role: role,
      content: message
    }
  end

  def user(message) do
    %__MODULE__{
      role: :user,
      content: message
    }
  end

  def system(message) do
    %__MODULE__{
      role: :system,
      content: message
    }
  end

  def assistant(message) do
    %__MODULE__{
      role: :assistant,
      content: message
    }
  end

end