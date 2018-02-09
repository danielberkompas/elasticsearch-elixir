defmodule Elasticsearch do
  @moduledoc """
  An Elixir interface to the Elasticsearch JSON API.

  ## Configuration

  You can customize the API module used by this module to make requests to
  the Elasticsearch API. (Default: `Elasticsearch.API.HTTP`)

      config :elasticsearch,
        api_module: MyApp.CustomAPI

  You can also specify default headers or default options to pass to
  `HTTPoison`.

      config :elasticsearch,
        default_headers: [{"authorization", "custom-value"}],
        default_options: [ssl: [{:versions, [:'tlsv1.2']}]]
  """

  alias Elasticsearch.Document

  @type response ::
          {:ok, map}
          | {:error, Elasticsearch.Exception.t()}

  @doc """
  Creates or updates a document in a given index.

  The document must implement the `Elasticsearch.Document` protocol.

  ## Example

      iex> Elasticsearch.Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> struct = %Post{id: 123, title: "Post", author: "Author"}
      ...> Elasticsearch.put_document(struct, "posts-1")
      {:ok,
       %{"_id" => "123", "_index" => "posts-1",
         "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
         "_type" => "post", "_version" => 1, "created" => true,
         "result" => "created"}}
  """
  @spec put_document(Document.t(), String.t()) :: response
  def put_document(document, index) do
    document
    |> document_url(index)
    |> put(Document.encode(document))
  end

  @doc """
  Same as `put_document/2`, but raises on errors.
  """
  @spec put_document!(Document.t(), String.t()) :: map
  def put_document!(document, index) do
    document
    |> put_document(index)
    |> unwrap!()
  end

  @doc """
  Deletes a document from a given index.

  The document must implement the `Elasticsearch.Document` protocol.
  """
  @spec delete_document(Document.t(), String.t()) :: response
  def delete_document(document, index) do
    document
    |> document_url(index)
    |> delete()
  end

  @doc """
  Same as `delete_document/2`, but raises on errors.
  """
  @spec delete_document!(Document.t(), String.t()) :: map
  def delete_document!(document, index) do
    document
    |> delete_document(index)
    |> unwrap!()
  end

  defp document_url(document, index) do
    "/#{index}/#{Document.type(document)}/#{Document.id(document)}"
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
          {:ok, map}
          | {:error, RuntimeError.t()}
          | {:error, Elasticsearch.Exception.t()}
  def wait_for_boot(tries, count \\ 0)

  def wait_for_boot(tries, count) when count == tries do
    {
      :error,
      RuntimeError.exception("""
      Elasticsearch could not be found after #{count} tries. Make sure it's running?
      """)
    }
  end

  def wait_for_boot(tries, count) do
    with {:error, _} <- get("/_cat/health?format=json") do
      :timer.sleep(1000)
      wait_for_boot(tries, count + 1)
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
  @spec get(String.t()) :: response
  @spec get(String.t(), Keyword.t()) :: response
  def get(url, opts \\ []) do
    url
    |> api_module().get(default_headers(), Keyword.merge(default_opts(), opts))
    |> format()
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
  @spec get!(String.t()) :: map
  @spec get!(String.t(), Keyword.t()) :: map
  def get!(url, opts \\ []) do
    url
    |> get(opts)
    |> unwrap!()
  end

  @doc """
  Puts data to a given Elasticsearch API path.

  ## Examples

      iex> Elasticsearch.Index.create_from_file("posts-1", "test/support/settings/posts.json")
      ...> Elasticsearch.put("/posts-1/post/id", %{"title" => "title", "author" => "author"})
      {:ok,
        %{"_id" => "id", "_index" => "posts-1",
          "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
          "_type" => "post", "_version" => 1, "created" => true,
          "result" => "created"}}

      iex> Elasticsearch.put("/bad/url", %{"title" => "title", "author" => "author"})
      {:error,
       %Elasticsearch.Exception{col: nil, line: nil,
        message: "No handler found for uri [/bad/url] and method [PUT]",
        query: nil, raw: nil, status: nil, type: nil}}
  """
  @spec put(String.t(), map | binary) :: response
  @spec put(String.t(), map | binary, Keyword.t()) :: response
  def put(url, data, opts \\ []) do
    url
    |> api_module().put(data, default_headers(), Keyword.merge(default_opts(), opts))
    |> format()
  end

  @doc """
  The same as `put/2`, but returns the response instead of a tuple. Raises on
  errors.

  ## Examples

      iex> Elasticsearch.Index.create_from_file("posts", "test/support/settings/posts.json")
      ...> Elasticsearch.put!("/posts/post/id", %{"name" => "name", "author" => "author"})
      %{"_id" => "id", "_index" => "posts",
        "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
        "_type" => "post", "_version" => 1, "created" => true,
        "result" => "created"}

      iex> Elasticsearch.put!("/bad/url", %{"data" => "here"})
      ** (Elasticsearch.Exception) No handler found for uri [/bad/url] and method [PUT]
  """
  @spec put!(String.t(), map) :: map
  @spec put!(String.t(), map, Keyword.t()) :: map
  def put!(url, data, opts \\ []) do
    url
    |> put(data, opts)
    |> unwrap!()
  end

  @doc """
  Posts data or queries to a given Elasticsearch path. If you want to execute
  an `Elasticsearch.Query`, see `execute/1` instead.

  ## Examples

      iex> Elasticsearch.Index.create_from_file("posts", "test/support/settings/posts.json")
      ...> query = %{"query" => %{"match_all" => %{}}}
      ...> {:ok, resp} = Elasticsearch.post("/posts/_search", query)
      ...> resp["hits"]["hits"]
      []
  """
  @spec post(String.t(), map) :: response
  @spec post(String.t(), map, Keyword.t()) :: response
  def post(url, data, opts \\ []) do
    url
    |> api_module().post(data, default_headers(), Keyword.merge(default_opts(), opts))
    |> format()
  end

  @doc """
  The same as `post/1`, but returns the response. Raises on errors.

  ## Examples

      iex> Elasticsearch.Index.create_from_file("posts", "test/support/settings/posts.json")
      ...> query = %{"query" => %{"match_all" => %{}}}
      ...> resp = Elasticsearch.post!("/posts/_search", query)
      ...> is_map(resp)
      true

  Raises an error if the path is invalid or another error occurs:

      iex> query = %{"query" => %{"match_all" => %{}}}
      ...> Elasticsearch.post!("/nonexistent/_search", query)
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec post!(String.t(), map) :: map
  @spec post!(String.t(), map, Keyword.t()) :: map
  def post!(url, data, opts \\ []) do
    url
    |> post(data, opts)
    |> unwrap!()
  end

  @doc """
  Deletes data at a given Elasticsearch URL.

  ## Examples

      iex> Elasticsearch.Index.create_from_file("posts", "test/support/settings/posts.json")
      ...> Elasticsearch.delete("/posts")
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
  @spec delete(String.t()) :: response
  @spec delete(String.t(), Keyword.t()) :: response
  def delete(url, opts \\ []) do
    format(api_module().delete(url, default_headers(), Keyword.merge(default_opts(), opts)))
  end

  @doc """
  Same as `delete/1`, but returns the response and raises errors.

  ## Examples

      iex> Elasticsearch.Index.create_from_file("posts", "test/support/settings/posts.json")
      ...> Elasticsearch.delete!("/posts")
      %{"acknowledged" => true}

  Raises an error if the resource is invalid.

      iex> Elasticsearch.delete!("/nonexistent")
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec delete!(String.t()) :: map
  @spec delete!(String.t(), Keyword.t()) :: map
  def delete!(url, opts \\ []) do
    url
    |> delete(opts)
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
  defp unwrap!({:error, exception}), do: raise(exception)

  defp api_module do
    config()[:api_module] || Elasticsearch.API.HTTP
  end

  defp default_opts do
    Application.get_env(:elasticsearch, :default_opts, [])
  end

  defp default_headers do
    Application.get_env(:elasticsearch, :default_headers, [])
  end

  defp config do
    Application.get_all_env(:elasticsearch)
  end
end