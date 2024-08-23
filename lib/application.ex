defmodule GenAI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  # @todo use extension repo for addons like local llama
  if Application.compile_env(:genai, :local_llama)[:enabled] && Code.ensure_loaded?(GenAI.Provider.LocalLLama) do
    @impl true
    def start(_type, _args) do
      children = [
        {Finch, name: GenAI.Finch},
        GenAI.Service.Model.MetaDataSupervisor,
        GenAI.Provider.LocalLLamaSupervisor
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: GenAI.Supervisor]
      Supervisor.start_link(children, opts)
    end
  else
    @impl true
    def start(_type, _args) do
      children = [
        {Finch, name: GenAI.Finch},
        GenAI.Service.Model.MetaDataSupervisor,
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: GenAI.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

end
