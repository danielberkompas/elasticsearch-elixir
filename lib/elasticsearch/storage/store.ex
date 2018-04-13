defmodule Elasticsearch.Store do
  @moduledoc """
  A behaviour for fetching data to index. Used by `mix elasticsearch.build`.
  """

  @typedoc """
  A data source. For example, `Post`, where `Post` is an `Ecto.Schema`.
  Each datum returned must implement `Elasticsearch.Document`.
  """
  @type source :: any

  @typedoc """
  Instances of the data source. For example, `%Post{}` structs.
  """
  @type data :: any

  @typedoc """
  The current offset for the query.
  """
  @type offset :: integer

  @typedoc """
  A limit on the number of elements to return.
  """
  @type limit :: integer

  @doc """
  Loads data based on the given source, offset, and limit.

  ## Example

      def load(Post, offset, limit) do
        Post
        |> offset(^offset)
        |> limit(^limit)
        |> Repo.all()
      end
  """
  @callback load(source, offset, limit) :: [data]
end
