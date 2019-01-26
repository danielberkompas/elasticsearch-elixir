defmodule Elasticsearch.Index.BulkTest do
  use Elasticsearch.DataCase

  import ExUnit.CaptureLog

  alias Elasticsearch.{
    Index.Bulk,
    Test.Cluster,
    Test.Store
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

  describe ".upload/4" do
    # Regression test for https://github.com/danielberkompas/elasticsearch-elixir/issues/10
    @tag :regression
    test "calls itself recursively properly" do
      assert {:error, [%TestException{}]} =
               Bulk.upload(Cluster, :posts, %{store: Store, sources: [Post]}, [
                 %TestException{}
               ])
    end

    test "collects errors properly" do
      populate_posts_table(1)

      assert {:error, [%Elasticsearch.Exception{type: "type", message: "reason"}]} =
               Cluster
               |> Elasticsearch.Cluster.Config.get()
               |> Map.put(:api, ErrorAPI)
               |> Bulk.upload(:posts, %{store: Store, sources: [Post]})
    end

    test "respects bulk_* settings" do
      populate_posts_table(2)
      populate_comments_table(2)

      Logger.configure(level: :debug)

      output =
        capture_log([level: :debug], fn ->
          Elasticsearch.Index.create_from_file(
            Cluster,
            "posts-bulk-test",
            "test/support/settings/posts.json"
          )

          Bulk.upload(Cluster, "posts-bulk-test", %{
            store: Store,
            sources: [Post],
            bulk_page_size: 1,
            bulk_wait_interval: 0
          })

          Elasticsearch.delete!(Cluster, "/posts-bulk-test")
        end)

      assert output =~ "Pausing 0ms between bulk pages"
    end
  end

  describe ".encode!/3" do
    test "respects _routing meta-field" do
      assert Bulk.encode!(Cluster, %Comment{id: "my-id", post_id: "123"}, "my-index") =~
               "\"_routing\":\"123\""
    end
  end
end
