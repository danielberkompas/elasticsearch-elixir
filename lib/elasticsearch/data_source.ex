defprotocol Elasticsearch.DataSource do
  @moduledoc """
  A protocol for fetching structs from a database to insert into Elasticsearch.
  Each struct that is returned must implement `Elasticsearch.Document`.

  ## Configuration
  
  The `Elasticsearch.DataSource` protocol will be used to fetch data from each
  `:source` specified in the `:sources` in your index configuration:

      config :elasticsearch,
        indexes: %{
          index1: %{
            alias: "index1_alias",
            schema: "priv/elasticsearch/index1.json",
            sources: [MyApp.SchemaName] # Each source must implement `DataSource`
          }
        }

  ## Example

  Since `:sources` will usually be a list of atoms, you can implement the
  `Elasticsearch.DataSource` protocol for `Atom`:
  
      defimpl Elasticsearch.DataSource, for: Atom do
        import Ecto.Query
        alias MyApp.Repo

        def fetch(MyApp.SchemaName = module, offset, limit) do
          module
          |> offset(^offset)
          |> limit(^limit)
          |> Repo.all
        end
      end

  If different modules should fetch their data differently, you can simply
  add additional `fetch` definitions:

      def fetch(MyApp.AnotherSchema = module, offset, limit) do
        module
        # ... custom logic here
      end
  """

  @type t :: any

  @doc """
  Returns a list of structs for the data source, based on `limit` and `offset`.
  The structs returned must implement `Elasticsearch.Document`.
  """
  @spec fetch(t, integer, integer) :: [map]
  def fetch(source, offset, limit)
end
