defmodule Elasticsearch do
  @moduledoc """
  An Elixir interface to the Elasticsearch API.
  """

  alias Elasticsearch.Document

  @type response ::
    {:ok, map} |
    {:error, Elasticsearch.Exception.t}

  @doc """
  Creates an index with the given name from either a JSON string or Elixir map.

  ## Examples

      iex> Elasticsearch.create_index("test1", "{}")
      :ok

      iex> Elasticsearch.create_index("test1", %{})
      :ok
  """
  @spec create_index(String.t, map | String.t) :: 
    :ok | 
    {:error, Elasticsearch.Exception.t}
  def create_index(name, settings) do
    with {:ok, _response} <- put("/#{name}", settings), do: :ok
  end

  @doc """
  Creates an index with the given name, with settings loaded from a JSON file.

  ## Example
  
      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      :ok

      iex> Elasticsearch.create_index_from_file("test2", "nonexistent.json")
      {:error, :enoent}
  """
  @spec create_index_from_file(String.t, Path.t) ::
    :ok |
    {:error, File.posix} |
    {:error, Elasticsearch.Exception.t}
  def create_index_from_file(name, file) do
    with {:ok, settings} <- File.read(file) do
      create_index(name, settings)
    end
  end

  @doc """
  Creates or updates a document in a given index.

  The document must implement the `Elasticsearch.Document` protocol.

  ## Example

      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> struct = %Type1{id: 123, name: "Post", author: "Author"}
      ...> Elasticsearch.put_document(struct, "test1")
      {:ok,
       %{"_id" => "123", "_index" => "test1",
         "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
         "_type" => "type1", "_version" => 1, "created" => true,
         "result" => "created"}}
  """
  @spec put_document(Document.t, String.t) :: response
  def put_document(document, index) do
    document
    |> document_url(index)
    |> put(Document.encode(document))
  end

  @doc """
  Same as `put_document/2`, but raises on errors.
  """
  @spec put_document!(Document.t, String.t) :: map
  def put_document!(document, index) do
    document
    |> put_document(index)
    |> unwrap!()
  end

  @doc """
  Deletes a document from a given index.

  The document must implement the `Elasticsearch.Document` protocol.
  """
  @spec delete_document(Document.t, String.t) :: response
  def delete_document(document, index) do
    document
    |> document_url(index)
    |> delete()
  end

  @doc """
  Same as `delete_document/2`, but raises on errors.
  """
  @spec delete_document!(Document.t, String.t) :: map
  def delete_document!(document, index) do
    document
    |> delete_document(index)
    |> unwrap!()
  end

  defp document_url(document, index) do
    "/#{index}/#{Document.type(document)}/#{Document.id(document)}"
  end

  @doc """
  Assigns an alias to a given index, simultaneously removing it from prior
  indexes, with zero downtime.

  ## Example
  
      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.alias_index("test1", "test")
      :ok
  """
  @spec alias_index(String.t, String.t) ::
    :ok |
    {:error, Elasticsearch.Exception.t}
  def alias_index(index_name, index_alias) do
    with {:ok, indexes} <- indexes_starting_with(index_alias),
         indexes = Enum.reject(indexes, &(&1 == index_name)) do

      remove_actions = 
        Enum.map indexes, fn(index) ->
          %{"remove" => %{"index" => index, "alias" => index_alias}}
        end

      actions = %{
        "actions" =>
          remove_actions ++
          [%{"add" => %{"index" => index_name, "alias" => index_alias}}
        ]
      }

      with {:ok, _response} <- post("/_aliases", actions), do: :ok
    end
  end

  @doc """
  Waits for Elasticsearch to be available at the configured url.

  It will try a given number of times, with 1sec delay between tries.

  ## Example

      iex> {:ok, resp} = Elasticsearch.wait_for_boot(15)
      ...> is_list(resp)
      true
  """
  @spec wait_for_boot(integer) ::
    {:ok, map} |
    {:error, RuntimeError.t} |
    {:error, Elasticsearch.Exception.t}
  def wait_for_boot(tries, count \\ 0)
  def wait_for_boot(tries, count) when count == tries do
    {:error, RuntimeError.exception("""
    Elasticsearch could not be found after #{count} tries. Make sure it's running?
    """)}
  end
  def wait_for_boot(tries, count) do
    with {:error, _} <- get("/_cat/health?format=json") do
      :timer.sleep(1000)
      wait_for_boot(tries, count + 1)
    end
  end

  @doc """
  Returns all indexes which start with a given string.

  ## Example
  
      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.create_index_from_file("test2", "priv/elasticsearch/index2.json")
      ...> Elasticsearch.indexes_starting_with("test")
      {:ok, ["test1", "test2"]}
  """
  def indexes_starting_with(prefix) do
    with {:ok, indexes} <- get("/_cat/indices?format=json") do
      indexes =
        indexes
        |> Enum.map(&(&1["index"]))
        |> Enum.filter(&String.starts_with?(&1, prefix))
        |> Enum.sort()

      {:ok, indexes}
    end
  end

  @doc """
  Gets the most recent index name with the given prefix.

  ## Examples

      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.create_index_from_file("test2", "priv/elasticsearch/index2.json")
      ...> Elasticsearch.latest_index_starting_with("test")
      {:ok, "test2"}

  If there are no indexes matching that prefix:

      iex> Elasticsearch.latest_index_starting_with("nonexistent")
      {:error, :not_found}
  """
  @spec latest_index_starting_with(String.t) ::
    {:ok, String.t} |
    {:error, :not_found} |
    {:error, Elasticsearch.Exception.t}
  def latest_index_starting_with(prefix) do
    with {:ok, indexes} <- indexes_starting_with(prefix) do
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
  
      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.refresh_index("test1")
      :ok
  """
  @spec refresh_index(String.t) :: :ok | {:error, Elasticsearch.Exception.t}
  def refresh_index(index_name) do
    with {:ok, _} <- post("/#{index_name}/_forcemerge?max_num_segments=5", %{}),
         {:ok, _} <- post("/#{index_name}/_refresh", %{}),
         do: :ok
  end

  @doc """
  Same as `refresh_index/1`, but raises an error on failure.

  ## Examples
  
      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.refresh_index!("test1")
      :ok

      iex> Elasticsearch.refresh_index!("nonexistent")
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec refresh_index!(String.t) :: :ok
  def refresh_index!(index_name) do
    case refresh_index(index_name) do
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

      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.clean_indexes_starting_with("test", 1)
      ...> Elasticsearch.indexes_starting_with("test")
      {:ok, ["test1"]}

  If `num_to_keep` is less than the number of indexes, the older indexes are
  deleted.

      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.clean_indexes_starting_with("test", 0)
      ...> Elasticsearch.indexes_starting_with("test")
      {:ok, []}
  """
  @spec clean_indexes_starting_with(String.t, integer) ::
    :ok |
    {:error, [Elasticsearch.Exception.t]}
  def clean_indexes_starting_with(prefix, num_to_keep) when is_integer(num_to_keep) do
    with {:ok, indexes} <- indexes_starting_with(prefix) do
      total = length(indexes)
      num_to_delete = total - num_to_keep
      num_to_delete = if num_to_delete >= 0, do: num_to_delete, else: 0

      errors = 
        indexes
        |> Enum.sort()
        |> Enum.take(num_to_delete)
        |> Enum.map(&delete("/#{&1}"))
        |> Enum.filter(&elem(&1, 0) == :error)
        |> Enum.map(&elem(&1, 1))

      if length(errors) > 0 do
        {:error, errors}
      else
        :ok
      end
    end
  end

  @doc """
  Gets the contents of a path from the Elasticsearch API.

  ## Examples

      iex> {:ok, resp} = Elasticsearch.get("/_cat/health?format=json")
      ...> is_list(resp)
      true

      iex> Elasticsearch.get("/nonexistent")
      {:error,
       %Elasticsearch.Exception{col: nil, line: nil,
        message: "no such index", query: nil,
        raw: %{"error" => %{"index" => "nonexistent",
            "index_uuid" => "_na_", "reason" => "no such index",
            "resource.id" => "nonexistent",
            "resource.type" => "index_or_alias",
            "root_cause" => [%{"index" => "nonexistent",
               "index_uuid" => "_na_", "reason" => "no such index",
               "resource.id" => "nonexistent",
               "resource.type" => "index_or_alias",
               "type" => "index_not_found_exception"}],
            "type" => "index_not_found_exception"}, "status" => 404},
        status: 404, type: "index_not_found_exception"}}
  """
  @spec get(String.t) :: response
  def get(url) do
    format(api_module().get(url))
  end

  @doc """
  The same as `get/1`, but returns the response instead of a tuple. Raises on
  errors.

  ## Examples

      iex> resp = Elasticsearch.get!("/_cat/health?format=json")
      ...> is_list(resp)
      true

      iex> Elasticsearch.get!("/nonexistent")
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec get!(String.t) :: map
  def get!(url) do
    url
    |> get()
    |> unwrap!()
  end

  @doc """
  Puts data to a given Elasticsearch API path.

  ## Examples
  
      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.put("/test1/type1/id", %{"name" => "name", "author" => "author"})
      {:ok,
        %{"_id" => "id", "_index" => "test1",
          "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
          "_type" => "type1", "_version" => 1, "created" => true,
          "result" => "created"}}

      iex> Elasticsearch.put("/bad/url", %{"name" => "name", "author" => "author"})
      {:error,
       %Elasticsearch.Exception{col: nil, line: nil,
        message: "No handler found for uri [/bad/url] and method [PUT]",
        query: nil, raw: nil, status: nil, type: nil}}
  """
  @spec put(String.t, map | binary) :: response
  def put(url, data) do
    format(api_module().put(url, data))
  end

  @doc """
  The same as `put/2`, but returns the response instead of a tuple. Raises on
  errors.

  ## Examples
  
      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.put!("/test1/type1/id", %{"name" => "name", "author" => "author"})
      %{"_id" => "id", "_index" => "test1",
        "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
        "_type" => "type1", "_version" => 1, "created" => true,
        "result" => "created"}

      iex> Elasticsearch.put!("/bad/url", %{"data" => "here"})
      ** (Elasticsearch.Exception) No handler found for uri [/bad/url] and method [PUT]
  """
  @spec put!(String.t, map) :: map
  def put!(url, data) do
    url
    |> put(data)
    |> unwrap!()
  end

  @doc """
  Posts data or queries to a given Elasticsearch path. If you want to execute
  an `Elasticsearch.Query`, see `execute/1` instead.

  ## Examples

      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> query = %{"query" => %{"match_all" => %{}}}
      ...> {:ok, resp} = Elasticsearch.post("/test1/_search", query)
      ...> resp["hits"]["hits"]
      []
  """
  @spec post(String.t, map) :: response
  def post(url, data) do
    format(api_module().post(url, data))
  end

  @doc """
  The same as `post/1`, but returns the response. Raises on errors.

  ## Examples

      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> query = %{"query" => %{"match_all" => %{}}}
      ...> resp = Elasticsearch.post!("/test1/_search", query)
      ...> resp["hits"]["hits"]
      []

  Raises an error if the path is invalid or another error occurs:

      iex> query = %{"query" => %{"match_all" => %{}}}
      ...> Elasticsearch.post!("/nonexistent/_search", query)
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec post!(String.t, map) :: map
  def post!(url, data) do
    url
    |> post(data)
    |> unwrap!()
  end

  @doc """
  Deletes data at a given Elasticsearch URL.

  ## Examples

      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.delete("/test1")
      {:ok, %{"acknowledged" => true}}

  It returns an error if the given resource does not exist.

      iex> Elasticsearch.delete("/nonexistent")
      {:error,
       %Elasticsearch.Exception{col: nil, line: nil,
        message: "no such index", query: nil,
        raw: %{"error" => %{"index" => "nonexistent",
            "index_uuid" => "_na_", "reason" => "no such index",
            "resource.id" => "nonexistent",
            "resource.type" => "index_or_alias",
            "root_cause" => [%{"index" => "nonexistent",
               "index_uuid" => "_na_", "reason" => "no such index",
               "resource.id" => "nonexistent",
               "resource.type" => "index_or_alias",
               "type" => "index_not_found_exception"}],
            "type" => "index_not_found_exception"}, "status" => 404},
        status: 404, type: "index_not_found_exception"}}
  """
  @spec delete(String.t) :: response
  def delete(url) do
    format(api_module().delete(url))
  end

  @doc """
  Same as `delete/1`, but returns the response and raises errors.

  ## Examples
  
      iex> Elasticsearch.create_index_from_file("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.delete!("/test1")
      %{"acknowledged" => true}

  Raises an error if the resource is invalid.

      iex> Elasticsearch.delete!("/nonexistent")
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec delete!(String.t) :: map
  def delete!(url) do
    url
    |> delete()
    |> unwrap!()
  end

  defp format({:ok, %{status_code: code, body: body}})
  when code >= 200 and code < 300 do
    {:ok, body}
  end

  defp format({:ok, %{body: body}}) do
    error = Elasticsearch.Exception.exception(response: body)
    {:error, error}
  end

  defp format(error), do: error

  defp unwrap!({:ok, value}), do: value
  defp unwrap!({:error, exception}), do: raise exception

  defp api_module do
    config()[:api_module] || Elasticsearch.API.HTTP
  end

  defp config do
    Application.get_all_env(:elasticsearch)
  end
end
