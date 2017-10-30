# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :elasticsearch,
  url: "http://localhost:9200",
  username: "username",
  password: "password",
  bulk_page_size: 5000,
  bulk_wait_interval: 15_000, # 15 seconds
  loader: Elasticsearch.Test.DataLoader,
  api_module: Elasticsearch.API.HTTP,
  indexes: %{
    index1: %{
      alias: "index1_alias",
      schema: "priv/elasticsearch/index1.json",
      sources: [Type1]
    },
    index2: %{
      alias: "index2_alias",
      schema: "priv/elasticsearch/index2.json",
      sources: [Type2]
    }
  }
