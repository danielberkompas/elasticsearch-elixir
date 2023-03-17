defmodule Elasticsearch.Test.Store do
  @behaviour Elasticsearch.Store

  alias Elasticsearch.Test.Repo

  @impl true
  def stream(Post) do
    Repo.stream(Post)
  end

  def stream(Comment) do
    Repo.stream(Comment)
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end
end
