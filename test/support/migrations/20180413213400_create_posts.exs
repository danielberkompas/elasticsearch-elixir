defmodule Elasticsearch.Test.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add(:title, :string)
      add(:author, :string)
    end
  end
end
