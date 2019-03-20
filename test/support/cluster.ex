defmodule Elasticsearch.Test.Cluster do
  @moduledoc false

  use Elasticsearch.Cluster

  def init(_config) do
    {:ok,
     %{
       api: Elasticsearch.API.HTTP,
       json_library: Poison,
       url: "http://localhost:9200",
       username: "username",
       password: "password",
       aws_access_key_id: "aws_access_key_id",
       aws_secret_access_key: "aws_secret_access_key",
       aws_region: "us-east-1",
       aws_service: "es",
       indexes: %{
         posts: %{
           settings: "test/support/settings/posts.json",
           store: Elasticsearch.Test.Store,
           sources: [Post],
           bulk_page_size: 5000,
           bulk_wait_interval: 0
         }
       }
     }}
  end
end
