defmodule Elasticsearch.DataStream do
  @moduledoc """
  Functions for building `Stream`s using the configured `Elasticsearch.Store`.
  See `stream/2`.
  """

  @type source :: any

  alias Elasticsearch.Cluster

  @doc """
  Creates a `Stream` from a given source.

  ## Example

      iex> stream = DataStream.stream(Cluster, MyApp.Schema, Elasticsearch.Test.Store)
      ...> is_function(stream)
      true

  """
  @spec stream(Cluster.t(), source, Elasticsearch.Store.t()) :: Stream.t()
  def stream(cluster, source, store) do
    config = Cluster.Config.get(cluster)
    Stream.resource(fn -> init(config) end, &next(&1, source, store), &finish/1)
  end

  # Store state in the following format:
  #
  # {items, offset, limit}
  defp init(config) do
    {[], 0, config.bulk_page_size}
  end

  # If no items, load another page of items
  defp next({[], offset, limit}, source, store) do
    load_page(source, store, offset, limit)
  end

  # If there are items, return the next item, and set the new state equal to
  # {tail, offset, limit}
  defp next({[h | t], offset, limit}, _source, _store) do
    {[h], {t, offset, limit}}
  end

  # Fetch a new page of items
  defp load_page(source, store, offset, limit) do
    case store.load(source, offset, limit) do
      # If the load returns no more items (i.e., we've iterated through them
      # all) then halt the stream and leave offset and limit unchanged.
      [] ->
        {:halt, {[], offset, limit}}

      # If the load returns items, then return the first item, and put the
      # tail into the state. Also, increment offset and limit by the
      # configured `:bulk_page_size`.
      [h | t] ->
        {[h], {t, offset + limit, limit}}
    end
  end

  # We don't need to do anything to clean up this Stream
  defp finish(_state) do
    nil
  end
end
