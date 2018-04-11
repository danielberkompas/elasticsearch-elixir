defmodule ElasticsearchTest do
  use ExUnit.Case

  alias Elasticsearch.{
    Index,
    Test.Cluster
  }

  doctest Elasticsearch

  setup do
    on_exit(fn ->
      Cluster
      |> Index.starting_with("posts")
      |> elem(1)
      |> Enum.map(&Elasticsearch.delete!(Cluster, "/#{&1}"))

      Elasticsearch.delete(Cluster, "/nonexistent")
    end)
  end
end
