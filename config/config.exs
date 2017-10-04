# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :hello_phoenix, HelloPhoenix.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Qne4Tn9kB/DZuCCenLIqcy3jkWloInlm6Z9OBh5/kLBiS0V8NZFZSA5GBloKdX/l",
  render_errors: [view: HelloPhoenix.ErrorView, accepts: ~w(html json)],
  pubsub: [name: HelloPhoenix.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :hello_phoenix, db_loc: "http://localhost:4000/json/"
config :hello_phoenix, front_end: "http://localhost:8000/#/"
config :hello_phoenix, fuseki_loc: "http://fuseki:3030/"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "prod.secret.exs"
import_config "#{Mix.env}.exs"
