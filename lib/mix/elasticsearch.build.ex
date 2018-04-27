defmodule Mix.Tasks.Elasticsearch.Build do
  @moduledoc """
  Builds Elasticsearch indexes using a zero-downtime, hot-swap technique.

  1. Build an index for the given `alias`, with a timestamp: `alias-12323123`
  2. Bulk upload data to that index using `store` and `sources`.
  3. Alias the `alias` to `alias-12323123`.
  4. Remove old indexes beginning with `alias`.
  5. Refresh `alias-12323123`.

  For a functional version of this approach, see
  `Elasticsearch.Index.hot_swap/4`.

  ## Options

  `--cluster`: The `Elasticsearch.Cluster` to build the indexes to.

  `--bulk-page-size`: (Optional) The number of documents to post to the cluster in each
  bulk page upload. Default: 5000

  `--bulk-wait-interval`: (Optional) The number of milliseconds to wait between posting
  each bulk page, to avoid overloading your cluster. Default: 0

  ## Example

      $ mix elasticsearch.build posts [index2] [index3] --cluster MyApp.Cluster

  To build an index only if it does not exist, use the `--existing` option:

      $ mix elasticsearch.build posts --existing --cluster MyApp.Cluster
      Index posts already exists.

  You can also specify `--bulk-page-size` and `--bulk-wait-interval` manually:

      $ mix elasticsearch.build posts --cluster MyApp.Cluster --bulk-page-size 1000 --bulk-wait-interval 500
  """

  require Logger

  import Maybe

  alias Elasticsearch.{
    Cluster.Config,
    Index
  }

  @doc false
  def run(args) do
    Mix.Task.run("app.start", [])

    {type, cluster, indexes, settings} = parse_args!(args)
    config = Config.get(cluster)

    for alias <- indexes do
      build(type, config, alias, settings)
    end
  end

  defp build(:existing, config, alias, settings) do
    case Index.latest_starting_with(config, alias) do
      {:ok, name} ->
        IO.puts("Index already exists: #{name}")

      {:error, :not_found} ->
        build(:rebuild, config, alias, settings)

      {:error, exception} ->
        Mix.raise(exception)
    end
  end

  defp build(:rebuild, config, alias, settings) do
    with :ok <- Index.hot_swap(config, alias, Map.merge(config.indexes[alias], settings)) do
      :ok
    else
      {:error, errors} when is_list(errors) ->
        errors = for error <- errors, do: "#{inspect(error)}\n"

        Mix.raise("""
        Index created, but not aliased: #{alias}
        The following errors occurred:

        #{errors}
        """)

      {:error, :enoent} ->
        Mix.raise("""
        Settings file not found at #{maybe(config, [:indexes, alias, :settings])}.
        """)

      {:error, exception} ->
        Mix.raise("""
        Index #{alias} could not be created.

            #{inspect(exception)}
        """)

      error ->
        Mix.raise(error)
    end
  end

  defp parse_args!(args) do
    {options, indexes} =
      OptionParser.parse!(
        args,
        strict: [
          cluster: :string,
          existing: :boolean,
          bulk_page_size: :integer,
          bulk_wait_interval: :integer
        ]
      )

    cluster =
      if options[:cluster] do
        :"Elixir.#{options[:cluster]}"
      else
        Mix.raise("""
        Please specify a cluster:

            --cluster MyApp.ClusterName
        """)
      end

    indexes =
      indexes
      |> Enum.map(&String.to_atom/1)
      |> MapSet.new()
      |> validate_indexes!(cluster)

    type = if options[:existing], do: :existing, else: :rebuild

    settings =
      options
      |> Keyword.take([:bulk_page_size, :bulk_wait_interval])
      |> Enum.into(%{})

    {type, cluster, indexes, settings}
  end

  defp validate_indexes!(indexes, cluster) do
    configured = configured_index_names(cluster)

    cond do
      MapSet.size(indexes) == 0 ->
        Mix.raise("""
        No indexes specified. The following indexes are configured:

            #{inspect(Enum.to_list(configured))}
        """)

      MapSet.subset?(indexes, configured) == false ->
        Mix.raise("""
        The following indexes are not configured:

            #{inspect(Enum.to_list(MapSet.difference(indexes, configured)))}
        """)

      true ->
        indexes
    end
  end

  defp configured_index_names(cluster) do
    cluster
    |> Config.get()
    |> Map.get(:indexes)
    |> Enum.map(fn {key, _val} -> key end)
    |> MapSet.new()
  end
end
