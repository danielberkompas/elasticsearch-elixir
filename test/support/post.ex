defmodule Post do
  @moduledoc false

  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    field(:author, :string)
  end
end

defimpl Elasticsearch.Document, for: Post do
  def id(post), do: post.id
  def type(_item), do: "post"
  def parent(_item), do: false
  def routing(_item), do: false

  def encode(post) do
    %{
      title: post.title,
      author: post.author,
      doctype: %{
        name: "post"
      }
    }
  end
end
