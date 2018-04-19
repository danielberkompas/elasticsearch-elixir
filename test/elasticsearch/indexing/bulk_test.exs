defmodule Elasticsearch.Index.BulkTest do
  use Elasticsearch.DataCase

  alias Elasticsearch.{
    Test.Cluster,
    Test.Store,
    Index.Bulk
  }

  defmodule TestException do
    defexception [:message]
  end

  defmodule ErrorAPI do
    @behaviour Elasticsearch.API

    @impl true
    def request(_config, :put, _url, _data, _opts) do
      {:ok,
       %HTTPoison.Response{
         status_code: 201,
         body: %{
           "errors" => true,
           "items" => [
             %{"create" => %{"error" => %{"type" => "type", "reason" => "reason"}}}
           ]
         }
       }}
    end
  end

  doctest Elasticsearch.Index.Bulk

  describe ".upload/5" do
    # Regression test for https://github.com/infinitered/elasticsearch-elixir/issues/10
    @tag :regression
    test "calls itself recursively properly" do
      assert {:error, [%TestException{}]} =
               Bulk.upload(Cluster, :posts, Store, [Post], [%TestException{}])
    end

    test "collects errors properly" do
      populate_posts_table(1)

      assert {:error, [%Elasticsearch.Exception{type: "type", message: "reason"}]} =
               Cluster
               |> Elasticsearch.Cluster.Config.get()
               |> Map.put(:api, ErrorAPI)
               |> Bulk.upload(:posts, Store, [Post])
    end
  end
end
