defmodule Elasticsearch.Index.BulkTest do
  use ExUnit.Case

  alias Elasticsearch.{
    Test.Cluster,
    Index.Bulk
  }

  doctest Elasticsearch.Index.Bulk
end
