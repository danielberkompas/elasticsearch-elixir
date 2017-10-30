defmodule Mix.Tasks.Elasticsearch.Build do
  @moduledoc """
  Builds Elasticsearch indexes using a zero-downtime, hot-swap technique.
  """

  require Logger

  alias Elasticsearch.Config

  @doc false
  def run(args) do
    Mix.Task.run("app.start", [])

    {indexes, type} = parse_args!(args)
    
    for index <- indexes do
      config = Config.config_for_index(index)
      build(config, type)
    end
  end

  defp build(config, :existing) do
    case Elasticsearch.latest_index_starting_with(config[:alias]) do
      {:ok, index_name} ->
        IO.puts("Index already exists: #{index_name}")
      {:error, :not_found} ->
        build(config, :rebuild)
      {:error, exception} ->
        Mix.raise(exception)
    end
  end

  defp build(config, :rebuild) do
    index_name = Config.build_index_name(config[:alias])

    with :ok <- Elasticsearch.create_index(index_name, config[:schema]),
         :ok <- Elasticsearch.Bulk.upload(index_name, config[:sources]),
         :ok <- Elasticsearch.alias_index(index_name, config[:alias]),
         :ok <- Elasticsearch.refresh_index(index_name) do
           :ok
    else
      {:error, errors} when is_list(errors) ->
        errors = for error <- errors, do: "#{inspect(error)}\n"

        Mix.raise """
        Index created, but not aliased: #{index_name}
        The following errors occurred:

        #{errors}
        """
      {:error, :enoent} ->
        Mix.raise """
        Schema file not found at #{config[:schema]}.
        """
      {:error, exception} ->
        Mix.raise """
        Index #{index_name} could not be created.

            #{inspect exception}
        """
      error ->
        Mix.raise(error)
    end
  end

  defp parse_args!(args) do
    {options, indexes} =
      OptionParser.parse!(args, switches: [
        existing: :boolean
      ])

    indexes =
      indexes
      |> Enum.map(&String.to_atom/1)
      |> MapSet.new

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
    configured = configured_index_names()

    cond do
      MapSet.size(indexes) == 0 ->
        Mix.raise """
        No indexes specified. The following indexes are configured:

            #{inspect Enum.to_list(configured)}
        """

      MapSet.subset?(indexes, configured) == false ->
        Mix.raise """
        The following indexes are not configured:

            #{inspect Enum.to_list(MapSet.difference(indexes, configured))}
        """
      true ->
        :ok
    end
  end

  defp configured_index_names do
    config()
    |> Keyword.get(:indexes)
    |> Enum.map(fn {key, _val} -> key end)
    |> MapSet.new
  end

  defp config do
    Application.get_all_env(:elasticsearch)
  end
end
