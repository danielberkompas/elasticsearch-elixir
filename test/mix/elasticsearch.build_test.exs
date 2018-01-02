defmodule Mix.Tasks.Elasticsearch.BuildTest do
  use ExUnit.Case

  import Mix.Task, only: [rerun: 2]
  import ExUnit.CaptureIO

  alias Elasticsearch

  setup do
    on_exit(fn ->
      "posts"
      |> Elasticsearch.indexes_starting_with()
      |> elem(1)
      |> Enum.map(&Elasticsearch.delete("/#{&1}"))
    end)
  end

  describe ".run" do
    test "raises error on invalid options" do
      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", ["--fake"])
      end
    end

    test "raises error on unconfigured indexes" do
      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", ["nonexistent"])
      end
    end

    test "raises error if no index specified" do
      assert_raise Mix.Error, fn ->
        rerun("elasticsearch.build", [])
      end
    end

    test "builds configured index" do
      rerun("elasticsearch.build", ["posts"])

      resp = Elasticsearch.get!("/posts/_search")
      assert resp["hits"]["total"] == 10_000
    end

    test "only keeps two index versions" do
      for _ <- 1..3 do
        rerun("elasticsearch.build", ["posts"])
        :timer.sleep(1000)
      end

      {:ok, indexes} = Elasticsearch.indexes_starting_with("posts")
      assert length(indexes) == 2
      [_previous, current] = Enum.sort(indexes)

      # assert that the most recent index is the one that is aliased
      assert {:ok, %{^current => _}} = Elasticsearch.get("/posts/_alias")
    end

    test "--existing checks if index exists" do
      rerun("elasticsearch.build", ["posts"])

      io =
        capture_io(fn ->
          rerun("elasticsearch.build", ["posts", "--existing"])
        end)

      assert io =~ "Index already exists: posts-"
    end
  end
end
