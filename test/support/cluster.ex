defmodule Elasticsearch.Test.Cluster do
  @moduledoc false

  use Elasticsearch.Cluster

  def init(_config) do
    {:ok,
     %{
       api: Elasticsearch.API.HTTP,
       bulk_page_size: 5000,
       bulk_wait_interval: 0,
       json_library: Poison,
       url: "http://localhost:9200",
       username: "username",
       password: "password",
       indexes: %{
         posts: %{
           settings: "test/support/settings/posts.json",
           store: Elasticsearch.Test.Store,
           sources: [Post]
         }
       }
     }}
  end
end
