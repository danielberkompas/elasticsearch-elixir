# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :elasticsearch,
  url: "http://localhost:9200",
  username: "username",
  password: "password",
  bulk_page_size: 5000,
  # 15 seconds
  bulk_wait_interval: 15_000,
  api_module: Elasticsearch.API.HTTP,
  json_library: Poison,
  indexes: %{
    posts: %{
      settings: "test/support/settings/posts.json",
      store: Elasticsearch.Test.Store,
      sources: [Post]
    }
  }
