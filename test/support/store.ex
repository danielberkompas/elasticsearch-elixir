defmodule Elasticsearch.Test.Store do
  @behaviour Elasticsearch.Store

  alias Elasticsearch.Test.Repo

  @impl true
  def stream(Post) do
    Repo.stream(Post)
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end
end
