defmodule Elasticsearch.Index do
  @moduledoc """
  Functions for manipulating Elasticsearch indexes.
  """

  alias Elasticsearch.Index.Bulk

  @doc """
  Creates an index using a zero-downtime hot-swap technique.

  1. Build an index for the given `alias`, with a timestamp: `alias-12323123`
  2. Bulk upload data to that index using `store` and `sources`.
  3. Alias the `alias` to `alias-12323123`.
  4. Remove old indexes beginning with `alias`.
  5. Refresh `alias-12323123`.

  This allows an old index to be served while a new index for `alias` is built.

  ## Example

      iex> file = "test/support/settings/posts.json"
      ...> store = Elasticsearch.Test.Store
      ...> Index.hot_swap("posts", file, store, [Post])
      :ok
  """
  @spec hot_swap(String.t() | atom, String.t(), Elasticsearch.Store.t(), list) ::
          :ok
          | {:error, Elasticsearch.Exception.t()}
  def hot_swap(alias, settings_file, store, sources) do
    name = build_name(alias)

    with :ok <- create_from_file(name, settings_file),
         :ok <- Bulk.upload(name, store, sources),
         :ok <- __MODULE__.alias(name, alias),
         :ok <- clean_starting_with(alias, 2),
         :ok <- refresh(name) do
      :ok
    end
  end

  @doc """
  Returns all indexes which start with a given string.

  ## Example

      iex> Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> Index.starting_with("posts")
      {:ok, ["posts-1"]}
  """
  @spec starting_with(String.t() | atom) ::
          {:ok, [String.t()]}
          | {:error, Elasticsearch.Exception.t()}
  def starting_with(prefix) do
    with {:ok, indexes} <- Elasticsearch.get("/_cat/indices?format=json") do
      prefix = to_string(prefix)

      indexes =
        indexes
        |> Enum.map(& &1["index"])
        |> Enum.filter(&String.starts_with?(&1, prefix))
        |> Enum.sort()

      {:ok, indexes}
    end
  end

  @doc """
  Assigns an alias to a given index, simultaneously removing it from prior
  indexes, with zero downtime.

  ## Example

      iex> Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> Index.alias("posts-1", "posts")
      :ok
  """
  @spec alias(String.t(), String.t()) ::
          :ok
          | {:error, Elasticsearch.Exception.t()}
  def alias(name, alias) do
    with {:ok, indexes} <- starting_with(alias), indexes = Enum.reject(indexes, &(&1 == name)) do
      remove_actions =
        Enum.map(indexes, fn index ->
          %{"remove" => %{"index" => index, "alias" => alias}}
        end)

      actions = %{
        "actions" => remove_actions ++ [%{"add" => %{"index" => name, "alias" => alias}}]
      }

      with {:ok, _response} <- Elasticsearch.post("/_aliases", actions), do: :ok
    end
  end

  @doc """
  Gets the most recent index name with the given prefix.

  ## Examples

      iex> Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> Index.create_from_file("posts-2", "test/support/settings/posts.json")
      ...> Index.latest_starting_with("posts")
      {:ok, "posts-2"}

  If there are no indexes matching that prefix:

      iex> Index.latest_starting_with("nonexistent")
      {:error, :not_found}
  """
  @spec latest_starting_with(String.t() | atom) ::
          {:ok, String.t()}
          | {:error, :not_found}
          | {:error, Elasticsearch.Exception.t()}
  def latest_starting_with(prefix) do
    with {:ok, indexes} <- starting_with(prefix) do
      index =
        indexes
        |> Enum.sort()
        |> List.last()

      case index do
        nil -> {:error, :not_found}
        index -> {:ok, index}
      end
    end
  end

  @doc """
  Refreshes a given index with recently added data.

  ## Example

      iex> Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> Index.refresh("posts-1")
      :ok
  """
  @spec refresh(String.t()) :: :ok | {:error, Elasticsearch.Exception.t()}
  def refresh(name) do
    with {:ok, _} <- Elasticsearch.post("/#{name}/_forcemerge?max_num_segments=5", %{}),
         {:ok, _} <- Elasticsearch.post("/#{name}/_refresh", %{}),
         do: :ok
  end

  @doc """
  Same as `refresh/1`, but raises an error on failure.

  ## Examples

      iex> Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> Index.refresh!("posts-1")
      :ok

      iex> Index.refresh!("nonexistent")
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec refresh!(String.t()) :: :ok
  def refresh!(name) do
    case refresh(name) do
      :ok ->
        :ok

      {:error, error} ->
        raise error
    end
  end

  @doc """
  Removes indexes starting with the given prefix, keeping a certain number.

  Can be used to garbage collect old indexes that are no longer used.

  ## Examples

  If there is only one index, and `num_to_keep` is >= 1, the index is not deleted.

      iex> Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> Index.clean_starting_with("posts", 1)
      ...> Index.starting_with("posts")
      {:ok, ["posts-1"]}

  If `num_to_keep` is less than the number of indexes, the older indexes are
  deleted.

      iex> Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> Index.clean_starting_with("posts", 0)
      ...> Index.starting_with("posts")
      {:ok, []}
  """
  @spec clean_starting_with(String.t(), integer) ::
          :ok
          | {:error, [Elasticsearch.Exception.t()]}
  def clean_starting_with(prefix, num_to_keep) when is_integer(num_to_keep) do
    with {:ok, indexes} <- starting_with(prefix) do
      total = length(indexes)
      num_to_delete = total - num_to_keep
      num_to_delete = if num_to_delete >= 0, do: num_to_delete, else: 0

      errors =
        indexes
        |> Enum.sort()
        |> Enum.take(num_to_delete)
        |> Enum.map(&Elasticsearch.delete("/#{&1}"))
        |> Enum.filter(&(elem(&1, 0) == :error))
        |> Enum.map(&elem(&1, 1))

      if length(errors) > 0 do
        {:error, errors}
      else
        :ok
      end
    end
  end

  @doc """
  Creates an index with the given name from either a JSON string or Elixir map.

  ## Examples

      iex> Index.create("posts-1", "{}")
      :ok
  """
  @spec create(String.t(), map | String.t()) ::
          :ok
          | {:error, Elasticsearch.Exception.t()}
  def create(name, settings) do
    with {:ok, _response} <- Elasticsearch.put("/#{name}", settings), do: :ok
  end

  @doc """
  Creates an index with the given name, with settings loaded from a JSON file.

  ## Example

      iex> Index.create_from_file("posts-1", "test/support/settings/posts.json")
      :ok

      iex> Index.create_from_file("posts-1", "nonexistent.json")
      {:error, :enoent}

  The `posts.json` file contains regular index settings as described in the
  Elasticsearch [documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html#_example_mapping):

      {
        "mappings": {
          "post": {
            "properties": {
              "title": {
                "type": "string"
              },
              "author": {
                "type": "string"
              }
            }
          }
        }
      }
  """
  @spec create_from_file(String.t(), Path.t()) ::
          :ok
          | {:error, File.posix()}
          | {:error, Elasticsearch.Exception.t()}
  def create_from_file(name, file) do
    with {:ok, settings} <- File.read(file) do
      create(name, settings)
    end
  end

  @doc """
  Generates a name for an index that will be aliased to a given `alias`.
  Similar to migrations, the name will contain a timestamp.

  ## Example

      Index.build_name("main")
      # => "main-1509581256"
  """
  @spec build_name(String.t() | atom) :: String.t()
  def build_name(alias) do
    "#{alias}-#{system_timestamp()}"
  end

  defp system_timestamp do
    DateTime.to_unix(DateTime.utc_now())
  end
end