defmodule Mix.Tasks.Elasticsearch.BuildTest do
  use Elasticsearch.DataCase, async: false

  import Mix.Task, only: [rerun: 2]
  import ExUnit.CaptureLog
  import ExUnit.CaptureIO

  alias Elasticsearch.Index
  alias Elasticsearch.Test.Cluster, as: TestCluster

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

    test "builds configured index" do
      populate_posts_table()

      Logger.configure(level: :debug)

      output =
        capture_log([level: :debug], fn ->
          rerun("elasticsearch.build", ["posts"] ++ @cluster_opts)
        end)

      assert output =~ "Pausing 0ms between bulk pages"
      resp = Elasticsearch.get!(TestCluster, "/posts/_search")
      assert resp["hits"]["total"] == 10_000
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
      assert resp["hits"]["total"] == 2
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

    defmodule ExistingIndexErrorAPI do
      @behaviour Elasticsearch.API

      @impl true
      def request(_config, :get, _url, _data, _opts) do
        {:ok,
         %HTTPoison.Response{
           status_code: 504,
           body: "Gateway Error"
         }}
      end
    end

    defmodule ExistingIndexErrorCluster do
      use Elasticsearch.Cluster

      def init(_config) do
        {:ok,
         %{
           api: ExistingIndexErrorAPI,
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
         }}
      end
    end

    test "--existing raises any error it encounters communicating with Elasticsearch" do
      {:ok, cluster} = ExistingIndexErrorCluster.start_link()

      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", [
          "posts",
          "--existing",
          "--cluster",
          inspect(ExistingIndexErrorCluster)
        ])
      end

      Process.exit(cluster, :kill)
    end
  end
end
