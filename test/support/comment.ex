defmodule Comment do
  @moduledoc false

  use Ecto.Schema

  schema "comments" do
    field(:body, :string)
    field(:author, :string)
    belongs_to(:post, Post)
  end
end

defimpl Elasticsearch.Document, for: Comment do
  def id(comment), do: comment.id
  def type(_item), do: "comment"
  def parent(_item), do: false
  def routing(comment), do: comment.post_id

  def encode(comment) do
    %{
      body: comment.body,
      author: comment.author,
      doctype: %{
        name: "comment",
        parent: comment.post_id
      }
    }
  end
end
