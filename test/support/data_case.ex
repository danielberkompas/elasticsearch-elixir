defmodule Elasticsearch.DataCase do
  @moduledoc false
  # This module defines the setup for tests requiring
  # access to the application's data layer.
  #
  # You may define functions here to be used as helpers in
  # your tests.
  #
  # Finally, if the test case interacts with the database,
  # it cannot be async. For this reason, every test runs
  # inside a transaction which is reset at the beginning
  # of the test unless the test case is marked as async.

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Elasticsearch.Test.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Elasticsearch.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Elasticsearch.Test.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Elasticsearch.Test.Repo, {:shared, self()})
    end

    Logger.configure(level: :warn)

    :ok
  end

  def populate_posts_table(quantity \\ 10_000) do
    posts =
      [%{title: "Example Post", author: "John Smith"}]
      |> Stream.cycle()
      |> Enum.take(quantity)

    Elasticsearch.Test.Repo.insert_all("posts", posts)
  end
end
