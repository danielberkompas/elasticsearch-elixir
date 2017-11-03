defmodule Elasticsearch.Builder do
  @moduledoc """
  Wrapper functions that make it easier to build indexes from scratch.
  """

  @doc """
  Creates an index using a zero-downtime hot-swap technique.

  1. Build an index for the given `alias`, with a timestamp: `alias-12323123`
  2. Bulk upload data to that index using `loader` and `sources`.
  3. Alias the `alias` to `alias-12323123`.
  4. Remove old indexes beginning with `alias`.
  5. Refresh `alias-12323123`.

  This allows an old index to be served while a new index for `alias` is built.

  ## Example

      iex> file = "test/support/settings/posts.json"
      ...> loader = Elasticsearch.Test.DataLoader
      ...> Builder.hot_swap_index("posts", file, loader, [Post])
      :ok
  """
  @spec hot_swap_index(String.t | atom, String.t, Elasticsearch.DataLoader.t, list) ::
    :ok |
    {:error, Elasticsearch.Exception.t}
  def hot_swap_index(alias, settings_file, loader, sources) do
    index_name = build_index_name(alias)

    with :ok <- Elasticsearch.create_index_from_file(index_name, settings_file),
         :ok <- Elasticsearch.Bulk.upload(index_name, loader, sources),
         :ok <- Elasticsearch.alias_index(index_name, alias),
         :ok <- Elasticsearch.clean_indexes_starting_with(alias, 2),
         :ok <- Elasticsearch.refresh_index(index_name) do
           :ok
         end
  end

  @doc """
  Generates a name for an index that will be aliased to a given `alias`.
  Similar to migrations, the name will contain a timestamp.

  ## Example

      Config.build_index_name("main")
      # => "main-1509581256"
  """
  @spec build_index_name(String.t | atom) :: String.t
  def build_index_name(alias) do
    "#{alias}-#{system_timestamp()}"
  end

  defp system_timestamp do
    DateTime.to_unix(DateTime.utc_now)
  end
end
