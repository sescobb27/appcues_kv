defmodule AppcuesIncrement.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = AppcuesIncrement.Telemetry.StatsdReporter.connect()

    children =
      [
        # Start the Ecto repository
        AppcuesIncrement.Repo,
        # Start the Telemetry supervisor
        AppcuesIncrementWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: AppcuesIncrement.PubSub},
        # Start the Endpoint (http/https)
        AppcuesIncrementWeb.Endpoint,
        {Registry, name: AppcuesIncrement.Registry, keys: :unique}

        # Start a worker by calling: AppcuesIncrement.Worker.start_link(arg)
        # {AppcuesIncrement.Worker, arg}
      ] ++ local_kvs()

    start_telemetry()

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

  defp local_kvs() do
    for index <- 1..AppcuesIncrement.Config.kvs_processes() do
      Supervisor.child_spec(
        {AppcuesIncrement.KV.Dist, index: index},
        id: "kv.dist.#{index}",
        # wait 1m to all keys to be synced to DB
        shutdown: 60_000
      )
    end
  end

  def start_telemetry() do
    metrics = [
      [:appcues, :kv, :dist, :increment],
      [:appcues, :kv, :dist, :sync_to_db],
      [:appcues, :kv, :sync, :increment],
      [:appcues, :api, :create_key],
      [:appcues, :api, :key_not_found],
      [:appcues, :api, :rate_limited]
    ]

    for metric <- metrics do
      :ok =
        :telemetry.attach(
          Enum.join(metric, "_"),
          metric,
          &AppcuesIncrement.Telemetry.Metrics.handle_event/4,
          nil
        )
    end
  end
end
