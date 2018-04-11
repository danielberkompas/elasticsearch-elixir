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

  ## Example

      $ mix elasticsearch.build posts [index2] [index3] --cluster MyApp.Cluster

  To build an index only if it does not exist, use the `--existing` option:

      $ mix elasticsearch.build posts --existing --cluster MyApp.Cluster
      Index posts already exists.
  """

  require Logger

  alias Elasticsearch.{
    Cluster.Config,
    Index
  }

  @doc false
  def run(args) do
    Mix.Task.run("app.start", [])

    {cluster, indexes, type} = parse_args!(args)
    config = Config.get(cluster)

    for alias <- indexes do
      build(config, alias, type)
    end
  end

  defp build(config, alias, :existing) do
    case Index.latest_starting_with(config, alias) do
      {:ok, name} ->
        IO.puts("Index already exists: #{name}")

      {:error, :not_found} ->
        build(config, alias, :rebuild)

      {:error, exception} ->
        Mix.raise(exception)
    end
  end

  defp build(config, alias, :rebuild) do
    %{settings: settings, store: store, sources: sources} = config.indexes[alias]

    with :ok <- Index.hot_swap(config, alias, settings, store, sources) do
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
        Schema file not found at #{settings}.
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
    {options, indexes} = OptionParser.parse!(args, strict: [cluster: :string, existing: :boolean])

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

    {cluster, indexes, type}
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
