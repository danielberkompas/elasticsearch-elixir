defmodule Elasticsearch.DataStream do
  @moduledoc """
  Functions for building `Stream`s using the configured 
  `Elasticsearch.DataLoader`.

      config :elasticsearch,
        # A module that implements the Elasticsearch.DataLoader behaviour
        loader: MyApp.ElasticsearchLoader
  """

  @type source :: any

  @doc """
  Creates a `Stream` from a given source.

  ## Configuration

  Your configured `:loader` module must handle the given data source.
  The stream will be paginated based on the `:bulk_page_size` in the 
  configuration.

      config :elasticsearch,
        bulk_page_size: 5000

  ## Example
  
      iex> stream = DataStream.stream(MyApp.Schema)
      ...> is_function(stream)
      true
      
  """
  @spec stream(source) :: Stream.t
  def stream(source) do
    Stream.resource(&init/0, &next(&1, source), &finish/1)
  end

  # Store state in the following format:
  #
  # {items, offset, limit}
  defp init do
    {[], 0, config()[:bulk_page_size]}
  end

  # If no items, load another page of items
  defp next({[], offset, limit}, source) do
    load_page(source, offset, limit)
  end

  # If there are items, return the next item, and set the new state equal to
  # {tail, offset, limit}
  defp next({[h | t], offset, limit}, _source) do
    {[h], {t, offset, limit}}
  end

  # Fetch a new page of items
  defp load_page(source, offset, limit) do
    page_size = config()[:bulk_page_size]

    case config()[:loader].load(source, offset, limit) do
      # If the load returns no more items (i.e., we've iterated through them
      # all) then halt the stream and leave offset and limit unchanged.
      [] -> 
        {:halt, {[], offset, limit}}

      # If the load returns items, then return the first item, and put the
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
