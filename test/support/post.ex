defmodule Post do
  @moduledoc false
  defstruct id: nil, title: nil, author: nil
end

defimpl Elasticsearch.Document, for: Post do
  def id(item), do: item.id
  def type(_item), do: "post"
  def parent(_item), do: false
  def encode(item) do
    %{
      title: item.title,
      author: item.author
    }
  end
end
