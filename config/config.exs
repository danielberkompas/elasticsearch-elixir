# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :elasticsearch,
  url: "url here",
  username: "username",
  password: "password",
  bulk_page_size: 5000,
  bulk_wait_interval: 15_000, # 15 seconds
  indexes: %{
    index1: %{
      alias: "index1_alias",
      schema: "priv/elasticsearch/index1.json",
      sources: [MyApp.Main] # Ecto schemas
    },
    index2: %{
      alias: "index2_alias",
      schema: "priv/elasticsearch/index2.json",
      sources: [MyApp.City]
    }
  }
