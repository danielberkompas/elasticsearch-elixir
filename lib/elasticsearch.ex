defmodule Elasticsearch do
  @moduledoc """
  """

  alias Elasticsearch.{
    Query
  }

  @type response ::
    {:ok, map} |
    {:error, Elasticsearch.Exception.t}

  @doc """
  Executes an `Elasticsearch.Query`, and returns the response.

  ## Example

      query = %Query{
        indexes: [:index1], 
        types: [:type1], 
        query: %{
          "size" => 1, 
          "query" => %{
            "match_all" => %{}
          }
        }
      }

      Elasticsearch.execute(query)
      # => {:ok, %{
      #   "_shards" => %{
      #     "failed" => 0, 
      #     "successful" => 5, 
      #     "total" => 5
      #   },
      #   "hits" => %{
      #     "hits" => [%{
      #       "_id" => "89phLzwlKSMUqKbTYoswsncqEb5vWdfDlteg+HuFLG4=",
      #       "_index" => "index1_alias-1509582436", "_score" => 1.0,
      #       "_source" => %{
      #         "author" => "Author", 
      #         "name" => "Name"
      #       },
      #       "_type" => "type1"
      #     }], 
      #     "max_score" => 1.0, 
      #     "total" => 10000
      #    },
      #    "timed_out" => false, 
      #    "took" => 1
      # }}
  """
  @spec execute(Query.t) :: response
  def execute(query) do
    post("#{Query.url(query)}", query.query)
  end

  @doc """
  Same as `execute/1`, but raises errors.

  ## Example
  
      iex> query = %Query{
      ...>   indexes: [:index1],
      ...>   types: [:type1],
      ...>   query: %{"query" => %{"match_all" => %{}}}
      ...> }
      ...> Elasticsearch.execute!(query)
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec execute!(Query.t) :: map
  def execute!(query) do
    case execute(query) do
      {:ok, response} ->
        response
      {:error, error} ->
        raise error
    end
  end

  @doc """
  Creates an index with the given name from a JSON schema file.

  ## Example
  
      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
      :ok

      iex> Elasticsearch.create_index("test2", "nonexistent.json")
      {:error, :enoent}
  """
  @spec create_index(String.t, Path.t) ::
    :ok |
    {:error, File.posix} |
    {:error, Elasticsearch.Exception.t}
  def create_index(name, schema) do
    with {:ok, contents} <- File.read(schema),
         {:ok, _response} <- put("/#{name}", contents) do
           :ok
    end
  end

  @doc """
  Assigns an alias to a given index, simultaneously removing it from prior
  indexes, with zero downtime.

  The previous index will be preserved, to make it easier to rollback to
  an earlier index.

  ## Example
  
      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
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

      # Delete all but the most recent index
      indexes_to_delete = indexes -- [List.last(indexes)]

      with {:ok, _} <- post("/_aliases", actions),
           :ok <- delete_indexes(indexes_to_delete) do
             :ok
      end
    end
  end

  @doc """
  Returns all indexes which start with a given string.

  ## Example
  
      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.create_index("test2", "priv/elasticsearch/index2.json")
      ...> Elasticsearch.indexes_starting_with("test")
      {:ok, ["test1", "test2"]}
  """
  def indexes_starting_with(prefix) do
    with {:ok, indexes} <- get("/_cat/indices?format=json") do
      indexes =
        indexes
        |> Stream.map(&(&1["index"]))
        |> Stream.filter(&String.starts_with?(&1, prefix))
        |> Enum.sort()

      {:ok, indexes}
    end
  end

  @doc """
  Gets the most recent index name with the given prefix.

  ## Examples

      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.create_index("test2", "priv/elasticsearch/index2.json")
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
  
      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
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
  
      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
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
  Deletes multiple indexes in one function call.

  If you only need to delete one index, see either of these two functions 
  instead:

  - `delete/1`
  - `delete!/1`

  ## Examples

  If any given index fails to delete, a list of `Elasticsearch.Exception`s will
  be returned.

      iex> Elasticsearch.delete_indexes(["nonexistent"])
      {:error,
        [%Elasticsearch.Exception{col: nil, line: nil,
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
          status: 404, type: "index_not_found_exception"}]}

  Otherwise, you'll get `:ok`:

      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
      ...> Elasticsearch.delete_indexes(["test1"])
      :ok
  """
  @spec delete_indexes([String.t]) ::
    :ok |
    {:error, [Elasticsearch.Exception.t]}
  def delete_indexes(indexes) do
    errors =
      indexes
      |> Stream.map(&delete("/#{&1}"))
      |> Stream.filter(&(elem(&1, 0) == :error))
      |> Enum.map(&elem(&1, 1))

    if errors == [] do
      :ok
    else
      {:error, errors}
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
  
      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
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
  
      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
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

      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
      ...> query = %{"query" => %{"match_all" => %{}}}
      ...> Elasticsearch.post("/test1/_search", query)
      {:ok,
       %{"_shards" => %{"failed" => 0, "successful" => 5, "total" => 5},
         "hits" => %{"hits" => [], "max_score" => nil, "total" => 0},
         "timed_out" => false, "took" => 1}}
  """
  @spec post(String.t, map) :: response
  def post(url, data) do
    format(api_module().post(url, data))
  end

  @doc """
  The same as `post/1`, but returns the response. Raises on errors.

  ## Examples

      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
      ...> query = %{"query" => %{"match_all" => %{}}}
      ...> Elasticsearch.post!("/test1/_search", query)
      %{"_shards" => %{"failed" => 0, "successful" => 5, "total" => 5},
        "hits" => %{"hits" => [], "max_score" => nil, "total" => 0},
        "timed_out" => false, "took" => 1}

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

      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
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
  
      iex> Elasticsearch.create_index("test1", "priv/elasticsearch/index1.json")
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
