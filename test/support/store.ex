defmodule Elasticsearch.Test.Store do
  @moduledoc false
  @behaviour Elasticsearch.Store

  def load(Post, offset, _limit) when offset <= 5_000 do
    [%Post{title: "Name", author: "Author"}]
    |> Stream.cycle()
    |> Stream.map(&Map.put(&1, :id, random_str()))
    |> Enum.take(5000)
  end

  def load(_module, _offset, _limit) do
    []
  end

  defp random_str do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end
end
