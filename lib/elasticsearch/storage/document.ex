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

  @doc """
  Returns the Elasticsearch `_routing` for the item. Elasticsearch
  default if this value is not provided is to use the `_id`.
  Setting this value to `false` or `nil` will omit sending the
  meta-field with your requests and use default routing behaviour.
  Routing allows you to control which shard the document should
  be directed to which is necessary for `join` fields.

  ## Example

  Specify a routing key to control the destination shard, like so:

      def routing(item), do: item.parent_id

  or omit routing and use default Elasticsearch functionality:

      def routing(_), do: false
  """
  @spec routing(any) :: any
  def routing(item)
end
