defmodule Mix.Tasks.Elasticsearch.BuildTest do
  use Elasticsearch.DataCase, async: false

  import Mix.Task, only: [rerun: 2]
  import ExUnit.CaptureLog
  import ExUnit.CaptureIO

  alias Elasticsearch.Index
  alias Elasticsearch.Test.Cluster, as: TestCluster

  defmodule GatewayErrorAPI do
    @behaviour Elasticsearch.API

    @impl true
    def request(_config, :get, _url, _data, _opts) do
      {:ok,
       %Req.Response{
         status: 504,
         body: "Gateway Error"
       }}
    end
  end

  defmodule BulkErrorAPI do
    @behaviour Elasticsearch.API

    @impl true
    def request(_config, method, _url, _data, _opts) when method in [:get, :post] do
      {:ok,
       %Req.Response{
         status: 200,
         body: []
       }}
    end

    def request(_config, :put, url, _data, _opts) do
      if url =~ "_bulk" do
        {:ok,
         %Req.Response{
           status: 201,
           body: %{
             "errors" => true,
             "items" => [
               %{"create" => %{"error" => %{"type" => "type", "reason" => "reason"}}}
             ]
           }
         }}
      else
        {:ok,
         %Req.Response{
           status: 201,
           body: ""
         }}
      end
    end
  end

  defmodule IndexErrorAPI do
    @behaviour Elasticsearch.API

    @impl true
    def request(_config, method, _url, _data, _opts) when method in [:get, :post] do
      {:ok,
       %Req.Response{
         status: 200,
         body: []
       }}
    end

    def request(_config, :put, _url, _data, _opts) do
      {:ok,
       %Req.Response{
         status: 504,
         body: "Gateway Error"
       }}
    end
  end

  defmodule ErrorCluster do
    use Elasticsearch.Cluster

    def init(config) do
      base = %{
        json_library: Poison,
        url: "http://localhost:9200",
        indexes: %{
          posts: %{
            store: Elasticsearch.Test.Store,
            settings: "test/support/settings/posts.json",
            sources: [Post],
            bulk_page_size: 1000,
            bulk_wait_interval: 0
          }
        }
      }

      {:ok, Map.merge(base, config)}
    end
  end

  setup do
    on_exit(fn ->
      Index.clean_starting_with(TestCluster, "posts", 0)
    end)
  end

  @cluster_opts ["--cluster", "Elasticsearch.Test.Cluster"]

  describe ".run" do
    test "raises error on invalid options" do
      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", ["--fake"])
      end
    end

    test "raises error if cluster not specified" do
      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", ["posts"])
      end
    end

    test "raises error on unconfigured indexes" do
      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", ["nonexistent"] ++ @cluster_opts)
      end
    end

    test "raises error if no index specified" do
      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", [] ++ @cluster_opts)
      end
    end

    test "raises error if errors occur during indexing" do
      populate_posts_table(1)

      {:ok, pid} = ErrorCluster.start_link(api: BulkErrorAPI)

      assert_raise Mix.Error,
                    "Index created, but not aliased: posts\nThe following errors occurred:\n\n    %Elasticsearch.Exception{status: nil, line: nil, col: nil, message: \"reason\", type: \"type\", query: nil, raw: %{\"error\" => %{\"reason\" => \"reason\", \"type\" => \"type\"}}}\n\n",
                   fn ->
                     rerun("elasticsearch.build", ["posts", "--cluster", inspect(ErrorCluster)])
                   end

      Process.exit(pid, :kill)
    end

    test "raises error if settings file not found" do
      {:ok, cluster} =
        ErrorCluster.start_link(
          api: Elasticsearch.API.HTTP,
          indexes: %{
            posts: %{
              settings: "priv/nonexistent.json",
              store: Elasticsearch.Test.Store,
              sources: [Post],
              bulk_page_size: 1,
              bulk_wait_interval: 0
            }
          }
        )

      assert_raise Mix.Error,
                   """
                   Settings file not found at priv/nonexistent.json.
                   """,
                   fn ->
                     rerun("elasticsearch.build", ["posts", "--cluster", inspect(ErrorCluster)])
                   end

      Process.exit(cluster, :kill)
    end

    test "raises error if index could not be created" do
      {:ok, cluster} = ErrorCluster.start_link(api: IndexErrorAPI)

      assert_raise Mix.Error,
                   "Index posts could not be created.\n\n    %Elasticsearch.Exception{status: nil, line: nil, col: nil, message: \"Gateway Error\", type: nil, query: nil, raw: nil}\n",
                   fn ->
                     rerun("elasticsearch.build", ["posts", "--cluster", inspect(ErrorCluster)])
                   end

      Process.exit(cluster, :kill)
    end

    test "builds configured index" do
      populate_posts_table()

      Logger.configure(level: :debug)

      output =
        capture_log([level: :debug], fn ->
          rerun("elasticsearch.build", ["posts"] ++ @cluster_opts)
        end)

      assert output =~ "Pausing 0ms between bulk pages"
      resp = Elasticsearch.get!(TestCluster, "/posts/_search")
      assert resp["hits"]["total"]["value"] == 10_000
    end

    test "respects --bulk options" do
      populate_posts_table(2)

      Logger.configure(level: :debug)

      output =
        capture_log([level: :debug], fn ->
          rerun(
            "elasticsearch.build",
            ["posts"] ++ @cluster_opts ++ ["--bulk-page-size", "1", "--bulk-wait-interval", "10"]
          )
        end)

      assert output =~ "Pausing 10ms between bulk pages"
      resp = Elasticsearch.get!(TestCluster, "/posts/_search")
      assert resp["hits"]["total"]["value"] == 2
    end

    test "only keeps two index versions" do
      for _ <- 1..3 do
        rerun("elasticsearch.build", ["posts"] ++ @cluster_opts)
        :timer.sleep(1000)
      end

      {:ok, indexes} = Index.starting_with(TestCluster, "posts")
      assert length(indexes) == 2
      [_previous, current] = Enum.sort(indexes)

      # assert that the most recent index is the one that is aliased
      assert {:ok, %{^current => _}} = Elasticsearch.get(TestCluster, "/posts/_alias")
    end

    test "--existing checks if index exists" do
      rerun("elasticsearch.build", ["posts"] ++ @cluster_opts)

      io =
        capture_io(fn ->
          rerun("elasticsearch.build", ["posts", "--existing"] ++ @cluster_opts)
        end)

      assert io =~ "Index already exists: posts-"
    end

    test "--existing rebuilds the index if it doesn't exist" do
      Index.clean_starting_with(TestCluster, "posts", 0)

      io =
        capture_io(fn ->
          rerun("elasticsearch.build", ["posts", "--existing"] ++ @cluster_opts)
        end)

      assert io == ""
      assert {:ok, _} = Elasticsearch.get(TestCluster, "/posts")
    end

    test "--existing raises any error it encounters communicating with Elasticsearch" do
      {:ok, cluster} = ErrorCluster.start_link(api: GatewayErrorAPI)

      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", [
          "posts",
          "--existing",
          "--cluster",
          inspect(ErrorCluster)
        ])
      end

      Process.exit(cluster, :kill)
    end
  end
end
