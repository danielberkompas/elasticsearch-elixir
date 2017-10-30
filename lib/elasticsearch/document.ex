defprotocol Elasticsearch.Document do
  @moduledoc """
  A protocol for converting a struct into an Elasticsearch document.

  ## Example

      defimpl Elasticsearch.Document, for: MyStruct do
        def id(model), do: model.id
        def type(_model), do: "model"
        def parent(_model), do: false
        def encode(model) do
          %{
            id: model.id,
            name: model.name
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
  Returns the Elasticsearch `_type` for the object.

  ## Example

      def type(_item), do: "item"
  """
  @spec type(any) :: String.t
  def type(item)

  @doc """
  Returns the parent ID of the document, or `false` if there is no parent.

  ## Examples
  
      # For structs that have parents
      def parent(%{parent_id: id}) when id != nil, do: id

      # For structs that don't have parents
      def parent(_item), do: false
  """
  @spec parent(any) :: false | any
  def parent(item)

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
