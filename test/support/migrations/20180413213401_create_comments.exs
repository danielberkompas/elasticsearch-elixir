defmodule Elasticsearch.Test.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add(:body, :string)
      add(:author, :string)
      add(:post_id, references(:posts, on_delete: :delete_all, on_update: :update_all))
    end
  end
end
