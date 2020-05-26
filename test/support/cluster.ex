defmodule Elasticsearch.Test.Cluster do
  @moduledoc false

  use Elasticsearch.Cluster

  def init(config) do
    url = Map.get(config, :url, "http://localhost:9200")

    {:ok,
     %{
       api: Elasticsearch.API.HTTP,
       json_library: Poison,
       url: url,
       username: "username",
       password: "password",
       indexes: %{
         posts: %{
           settings: "test/support/settings/posts.json",
           store: Elasticsearch.Test.Store,
           sources: [Post],
           bulk_page_size: 5000,
           bulk_wait_interval: 0
         }
       },
       default_options: [
         aws: [
           region: "us-east-1",
           service: "es",
           access_key: "aws_access_key_id",
           secret: "aws_secret_access_key"
         ]
       ]
     }}
  end
end
