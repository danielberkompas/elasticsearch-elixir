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

  doctest Elasticsearch.Index.Bulk

  describe ".upload/5" do
    # Regression test for https://github.com/infinitered/elasticsearch-elixir/issues/10
    @tag :regression
    test "calls itself recursively properly" do
      assert {:error, [%TestException{}]} =
               Bulk.upload(Cluster, :posts, Store, [Post], [%TestException{}])
    end
  end
end
