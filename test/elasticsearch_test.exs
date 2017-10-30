defmodule ElasticsearchTest do
  use ExUnit.Case
  doctest Elasticsearch

  test "greets the world" do
    assert Elasticsearch.hello() == :world
  end
end
