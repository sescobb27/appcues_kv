# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :appcues_increment,
  ecto_repos: [AppcuesIncrement.Repo],
  generators: [binary_id: true]

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

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
