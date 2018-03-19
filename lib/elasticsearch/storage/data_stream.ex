defmodule Elasticsearch.DataStream do
  @moduledoc """
  Functions for building `Stream`s using the configured `Elasticsearch.Store`.
  See `stream/2`.
  """

  @type source :: any

  alias Elasticsearch.Config

  @doc """
  Creates a `Stream` from a given source.

  ## Configuration

  Your configured `:store` module must handle the given data source.
  The stream will be paginated based on the `:bulk_page_size` in the
  configuration.

      config :elasticsearch,
        bulk_page_size: 5000

  ## Example

      iex> stream = DataStream.stream(MyApp.Schema, Elasticsearch.Test.Store)
      ...> is_function(stream)
      true

  """
  @spec stream(source, Elasticsearch.Store.t()) :: Stream.t()
  def stream(source, store) do
    Stream.resource(&init/0, &next(&1, source, store), &finish/1)
  end

  # Store state in the following format:
  #
  # {items, prev_page_count, offset, limit}
  defp init do
    page_size = Config.all()[:bulk_page_size]
    {[], page_size, 0, page_size}
  end

  # If no items, and the previous page was equal to the expected size,
  # then load another page of items.
  #
  # There might be another page of data to fetch.
  defp next({[], prev_page_size, offset, limit} = state, source, store)
       when prev_page_size == limit do
    case store.load(source, offset, limit) do
      # If the load returns no more items (i.e., we've iterated through them
      # all) then halt the stream and leave offset and limit unchanged.
      [] ->
        {:halt, state}

      # If the load returns items, then return the first item, and put the
      # tail into the state. Also, increment offset by the configured
      # `:bulk_page_size`.
      [h | t] = items ->
        {[h], {t, length(items), offset + limit, limit}}
    end
  end

  # If there are no remaining items, and the previous page size was smaller
  # than the expected page size, we know we are at the end, so we halt.
  defp next({[], prev_page_size, _offset, limit} = state, _source, _store)
       when prev_page_size < limit do
    {:halt, state}
  end

  # If there are items, return the next item, and set the new state equal to
  # {tail, offset, limit}
  defp next({[h | t], prev_page_size, offset, limit}, _source, _store) do
    {[h], {t, prev_page_size, offset, limit}}
  end

  # We don't need to do anything to clean up this Stream
  defp finish(_state) do
    nil
  end
end
