defmodule ElasticsearchTest do
  use ExUnit.Case

  doctest Elasticsearch

  setup do
    on_exit(fn ->
      "posts"
      |> Elasticsearch.Index.starting_with()
      |> elem(1)
      |> Enum.map(&Elasticsearch.delete!("/#{&1}"))

      Elasticsearch.delete("/nonexistent")
    end)
  end
end
