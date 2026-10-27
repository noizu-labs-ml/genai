defmodule GenAI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @doc """
  〚🔧:b87594b8-fe0b-5571-a322-7867fce2c088〛 start :: Boots the GenAI supervision tree (Finch HTTP client).
  """
  def start(_type, _args) do
    children = [
      {Finch, name: GenAI.Finch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GenAI.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
