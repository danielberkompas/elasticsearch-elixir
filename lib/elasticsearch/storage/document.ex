defprotocol Elasticsearch.Document do
  @moduledoc """
  A protocol for converting a struct into an Elasticsearch document.

  ## Example

      defimpl Elasticsearch.Document, for: MyStruct do
        def id(struct), do: struct.id
        def encode(struct) do
          %{
            id: struct.id,
            name: struct.name
          }
        end
      end
  """

  @doc """
  Returns the Elasticsearch `_id` for the item.

  ## Example

      def id(item), do: item.id
  """
  @spec id(any) :: any
  def id(item)

  @doc """
  Returns a map of fields, which will be converted to JSON and stored in
  Elasticsearch as a document.

  ## Example

      def encode(item) do
        %{
          title: item.title,
          author: item.author
        }
      end
  """
  @spec encode(any) :: map
  def encode(item)
end
