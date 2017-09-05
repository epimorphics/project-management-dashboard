use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hello_phoenix, HelloPhoenix.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :hello_phoenix, HelloPhoenix.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "hello_phoenix_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :hello_phoenix, :slack_api, Slack.Test
config :hello_phoenix, :github_api, Github.Test
config :hello_phoenix, :jenkins_api, Jenkins.Test
config :hello_phoenix, :codebasehq_api, CodebaseHQ.Test
config :hello_phoenix, :fuseki_api, Fuseki.Test
