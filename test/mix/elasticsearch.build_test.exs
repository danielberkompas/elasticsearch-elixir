defmodule Mix.Tasks.Elasticsearch.BuildTest do
  use Elasticsearch.DataCase, async: false

  import Mix.Task, only: [rerun: 2]
  import ExUnit.CaptureLog
  import ExUnit.CaptureIO

  alias Elasticsearch.Index
  alias Elasticsearch.Test.Cluster, as: TestCluster

  setup do
    on_exit(fn ->
      TestCluster
      |> Index.starting_with("posts")
      |> elem(1)
      |> Enum.map(&Elasticsearch.delete(TestCluster, "/#{&1}"))
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
  end
end
