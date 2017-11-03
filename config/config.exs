# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :elasticsearch,
  url: "http://localhost:9200",
  username: "username",
  password: "password",
  bulk_page_size: 5000,
  bulk_wait_interval: 15_000, # 15 seconds
  api_module: Elasticsearch.API.HTTP,
  indexes: %{
    posts: %{
      settings: "test/support/settings/posts.json",
      loader: Elasticsearch.Test.DataLoader,
      sources: [Post]
    },
  }
