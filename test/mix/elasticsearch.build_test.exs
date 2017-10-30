defmodule Mix.Tasks.Elasticsearch.BuildTest do
  use ExUnit.Case

  import Mix.Task, only: [rerun: 2]
  import ExUnit.CaptureIO

  alias Elasticsearch

  setup do
    on_exit fn ->
      for index <- ["index1_alias"] do
        Elasticsearch.delete("/#{index}")
      end
    end
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
      rerun("elasticsearch.build", ["index1"])

      resp = Elasticsearch.get!("/index1_alias/_search")
      assert resp["hits"]["total"] == 10_000
    end

    test "only keeps two index versions" do
      for _ <- 1..3 do
        rerun("elasticsearch.build", ["index1"])
        :timer.sleep(1000)
      end

      {:ok, indexes} = Elasticsearch.indexes_starting_with("index1")
      assert length(indexes) == 2
    end

    test "--existing checks if index exists" do
      rerun("elasticsearch.build", ["index1"])

      io =
        capture_io fn ->
          rerun("elasticsearch.build", ["index1", "--existing"])
        end

      assert io =~ "Index already exists: index1_alias-"
    end
  end
end
