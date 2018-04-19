defmodule Elasticsearch.Index.BulkTest do
  use Elasticsearch.DataCase

  alias Elasticsearch.{
    Test.Cluster,
    Index.Bulk
  }

  doctest Elasticsearch.Index.Bulk
end
