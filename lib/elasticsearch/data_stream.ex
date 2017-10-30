defmodule Elasticsearch.DataStream do
  @moduledoc """
  Functions for building `Stream`s out of `Elasticsearch.DataSource`s.
  See `stream/1` for details.
  """

  alias Elasticsearch.DataSource

  @doc """
  Creates a `Stream` from a given `Elasticsearch.DataSource`.

  ## Configuration

  You must first implement the `Elasticsearch.DataSource` protocol for the
  source that you want to stream. The stream will be paginated based on
  the `:bulk_page_size` in the configuration.

      config :elasticsearch,
        bulk_page_size: 5000

  ## Example
  
      iex> stream = DataStream.stream(MyApp.Schema)
      ...> is_function(stream)
      true
      
  """
  @spec stream(DataSource.t) :: Stream.t
  def stream(source) do
    Stream.resource(&init/0, &next(&1, source), &finish/1)
  end

  # Store state in the following format:
  #
  # {items, offset, limit}
  defp init do
    {[], 0, config()[:bulk_page_size]}
  end

  # If no items, fetch another page of items
  defp next({[], offset, limit}, source) do
    fetch_page(source, offset, limit)
  end

  # If there are items, return the next item, and set the new state equal to
  # {tail, offset, limit}
  defp next({[h | t], offset, limit}, _source) do
    {[h], {t, offset, limit}}
  end

  # Fetch a new page of items
  defp fetch_page(source, offset, limit) do
    page_size = config()[:bulk_page_size]

    case DataSource.fetch(source, offset, limit) do
      # If the fetch returns no more items (i.e., we've iterated through them
      # all) then halt the stream and leave offset and limit unchanged.
      [] -> 
        {:halt, {[], offset, limit}}

      # If the fetch returns items, then return the first item, and put the
      # tail into the state. Also, increment offset and limit by the
      # configured `:bulk_page_size`.
      [h | t] ->
        {[h], {t, offset + page_size, limit + page_size}}
    end
  end

  # We don't need to do anything to clean up this Stream
  defp finish(_state) do
    nil
  end

  defp config do
    Application.get_all_env(:elasticsearch)
  end
end
