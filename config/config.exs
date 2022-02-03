# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :appcues_increment,
  ecto_repos: [AppcuesIncrement.Repo],
  generators: [binary_id: true],
  # values are: ["sync", "dist"]
  strategy: "dist",
  sync_interval: 5000

config :appcues_increment, AppcuesIncrement.Repo,
  migration_primary_key: [type: :uuid],
  migration_timestamps: [type: :utc_datetime]

# Configures the endpoint
config :appcues_increment, AppcuesIncrementWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AppcuesIncrementWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: AppcuesIncrement.PubSub,
  live_view: [signing_salt: "sXrZ9sDq"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, level: :warn

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :statix, AppcuesIncrement.Telemetry.StatsdReporter,
  prefix: "appcues_kv",
  pool_size: 5,
  tags: ["env:#{Mix.env()}"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
