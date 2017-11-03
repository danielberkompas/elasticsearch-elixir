defmodule Elasticsearch.BuilderTest do
  use ExUnit.Case

  alias Elasticsearch.Builder

  doctest Elasticsearch.Builder

  setup do
    for index <- ["posts"] do
      Elasticsearch.delete("/#{index}")
    end
  end
end
