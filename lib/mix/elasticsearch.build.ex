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

      $ mix elasticsearch.build posts [index2] [index3]

  To build an index only if it does not exist, use the `--existing` option:
      
      $ mix elasticsearch.build posts --existing
      Index posts already exists.
  """

  require Logger

  alias Elasticsearch.{
    Index,
    Config
  }

  @doc false
  def run(args) do
    Mix.Task.run("app.start", [])

    {indexes, type} = parse_args!(args)

    for alias <- indexes do
      config = Config.config_for_index(alias)
      build(alias, config, type)
    end
  end

  defp build(alias, config, :existing) do
    case Index.latest_starting_with(alias) do
      {:ok, name} ->
        IO.puts("Index already exists: #{name}")

      {:error, :not_found} ->
        build(alias, config, :rebuild)

      {:error, exception} ->
        Mix.raise(exception)
    end
  end

  defp build(alias, %{settings: settings, store: store, sources: sources}, :rebuild) do
    with :ok <- Index.hot_swap(alias, settings, store, sources) do
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
    {options, indexes} =
      OptionParser.parse!(
        args,
        switches: [
          existing: :boolean
        ]
      )

    indexes =
      indexes
      |> Enum.map(&String.to_atom/1)
      |> MapSet.new()

    type =
      cond do
        options[:existing] ->
          :existing

        true ->
          :rebuild
      end

    validate_indexes!(indexes)

    {indexes, type}
  end

  defp validate_indexes!(indexes) do
    configured = configured_names()

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
        :ok
    end
  end

  defp configured_names do
    config()
    |> Keyword.get(:indexes)
    |> Enum.map(fn {key, _val} -> key end)
    |> MapSet.new()
  end

  defp config do
    Application.get_all_env(:elasticsearch)
  end
end
