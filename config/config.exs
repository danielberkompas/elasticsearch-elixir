# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :elasticsearch, Elasticsearch.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
  database: "elasticsearch_test",
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/"

config :elasticsearch, ecto_repos: [Elasticsearch.Test.Repo]

config :logger, level: :debug
