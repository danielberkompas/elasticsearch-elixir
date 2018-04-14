defmodule Elasticsearch.Cluster.IndexTest do
  use Elasticsearch.DataCase, async: false

  alias Elasticsearch.{
    Index,
    Test.Cluster
  }

  doctest Elasticsearch.Index

  setup do
    for index <- ["posts"] do
      Elasticsearch.delete(Cluster, "/#{index}*")
    end
  end
end
