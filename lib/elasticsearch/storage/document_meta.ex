defprotocol Elasticsearch.DocumentMeta do
  @fallback_to_any true
  @moduledoc """
  A protocol for converting a struct into an Elasticsearch meta-fields.

  ## Example

      defimpl Elasticsearch.DocumentMeta, for: MyStruct do
        def routing(struct), do: struct.id
      end
  """

  @doc """
  Returns the Elasticsearch `_routing` for the item. Elasticsearch
  default if this value is not provided is to use the `_id`.

  ## Example

      def routing(item), do: item.id
  """
  @spec routing(any) :: any
  def routing(item)
end

defimpl Elasticsearch.DocumentMeta, for: Any do
  def routing(_), do: nil
end
