defmodule Elasticsearch.DataStreamTest do
  use ExUnit.Case

  alias Elasticsearch.DataStream

  doctest Elasticsearch.DataStream

  defmodule TestStore do
    def load(_thing, offset, _limit) when offset == 0 do
      send(self(), :loaded_once)

      [
        %{one: 1},
        %{two: 2},
        %{three: 3}
      ]
    end

    def load(_thing, _offset, _limit) do
      send(self(), :loaded_twice)
      []
    end
  end

  # See https://github.com/infinitered/elasticsearch-elixir/issues/10
  @tag :regression
  test "handles store values" do
    stream = DataStream.stream(:thing, TestStore)

    assert Enum.to_list(stream) == [
             %{one: 1},
             %{two: 2},
             %{three: 3}
           ]

    assert_received :loaded_once
    refute_received :loaded_twice
  end
end
