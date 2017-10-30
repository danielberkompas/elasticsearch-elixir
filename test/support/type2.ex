defmodule Type2 do
  @moduledoc false
  defstruct name: nil, author: nil
end

defimpl Elasticsearch.Document, for: Type2 do
  def id(item), do: item.name
  def type(_item), do: "type1"
  def parent(_item), do: false
  def encode(item) do
    %{
      name: item.name,
      author: item.author
    }
  end
end
