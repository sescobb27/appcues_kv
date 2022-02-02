defmodule AppcuesIncrement.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      AppcuesIncrement.Repo,
      # Start the Telemetry supervisor
      AppcuesIncrementWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: AppcuesIncrement.PubSub},
      # Start the Endpoint (http/https)
      AppcuesIncrementWeb.Endpoint
      # Start a worker by calling: AppcuesIncrement.Worker.start_link(arg)
      # {AppcuesIncrement.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AppcuesIncrement.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppcuesIncrementWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
