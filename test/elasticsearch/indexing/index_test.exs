defmodule Elasticsearch.IndexTest do
  use ExUnit.Case

  alias Elasticsearch.Index

  doctest Elasticsearch.Index

  setup do
    for index <- ["posts"] do
      Elasticsearch.delete("/#{index}")
    end
  end
end