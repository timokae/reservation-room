# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :reservation_server,
  ecto_repos: [ReservationServer.Repo],
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET"),
  redirect_uri: System.get_env("GOOGLE_REDIRECT_URI"),
  refresh_token: System.get_env("GOOGLE_REFRESH_TOKEN")

# Configures the endpoint
config :reservation_server, ReservationServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ejj93zeGtx1jmsqdbeuf1BhC0fviXczdKDdukBAaDx6pJcI7/PC+Mb+ZalkwJets",
  render_errors: [view: ReservationServerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ReservationServer.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
