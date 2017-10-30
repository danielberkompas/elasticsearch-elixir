defmodule Type1 do
  @moduledoc false
  defstruct id: nil, name: nil, author: nil
end

defimpl Elasticsearch.Document, for: Type1 do
  def id(item), do: item.id
  def type(_item), do: "type1"
  def parent(_item), do: false
  def encode(item) do
    %{
      name: item.name,
      author: item.author
    }
  end
end
