defmodule Elasticsearch.Test.Store do
  @behaviour Elasticsearch.Store

  alias Elasticsearch.Test.Repo
  import Ecto.Query

  @impl true
  def stream(Post) do
    Repo.stream(Post)
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end

  def load(Comment, offset, limit) do
    Comment
    |> offset(^offset)
    |> limit(^limit)
    |> preload([:post])
    |> Repo.all()
  end
end
