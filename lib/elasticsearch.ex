defmodule Elasticsearch do
  @moduledoc """
  Entry-point for interacting with your Elasticsearch cluster(s).

  You should configure at least one `Elasticsearch.Cluster` in order to
  use the functions in this module, or else you'll need to pass all the
  configuration for the cluster into each function call.

  ### Telemetry

  The following events are published:

    * `[:elasticsearch, :request, :start]` - emitted at the beginning of the request to Elasticsearch.
      * Measurement: `%{system_time: System.system_time()}`
      * Metadata: `%{telemetry_span_context: term(), config: Elasticsearch.Cluster.config(),
        method: Elasticsearch.API.method(), url: Elasticsearch.API.url(), data: Elasticsearch.API.data()}`

    * `[:elasticsearch, :request, :stop]` - emitted at the end of the request to Elasticsearch.
      * Measurement: `%{duration: native_time}`
      * Metadata: `%{telemetry_span_context: term(), result: Elasticsearch.API.response()}`

    * `[:elasticsearch, :request, :exception]` - emitted when an exception has been raised.
      * Measurement: `%{system_time: System.system_time()}`
      * Metadata: `%{telemetry_span_context: term(), kind: Exception.kind(), reason: term(),
        stacktrace: Exception.stacktrace()}`
  """

  alias Elasticsearch.{
    Document,
    Cluster,
    Cluster.Config
  }

  @type index_name :: String.t()
  @type url :: Path.t()
  @type opts :: Keyword.t()
  @type data :: map | String.t()
  @type response :: {:ok, map} | {:error, Elasticsearch.Exception.t()}

  @doc """
  Creates or updates a document in a given index.

  The document must implement the `Elasticsearch.Document` protocol.

  ## Example

      iex> Index.create_from_file(Cluster, "posts-1", "test/support/settings/posts.json")
      ...> struct = %Post{id: 123, title: "Post", author: "Author"}
      ...> Elasticsearch.put_document(Cluster, struct, "posts-1")
      {:ok,
        %{
          "_id" => "123",
          "_index" => "posts-1",
          "_primary_term" => 1,
          "_seq_no" => 0,
          "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
          "_type" => "_doc",
          "_version" => 1,
          "result" => "created"
        }}
  """
  @spec put_document(Cluster.t(), Document.t(), index_name) :: response
  def put_document(cluster, document, index) do
    put(cluster, document_url(document, index), Document.encode(document))
  end

  @doc """
  Creates a document in a given index. Use this function when your documents
  do not have IDs or you want to use Elasticsearch's automatic ID generation.

  https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html#_automatic_id_generation

  The document must implement the `Elasticsearch.Document`. protocol.

  ## Example


      Index.create_from_file(Cluster, "posts-1", "test/support/settings/posts.json")
      Elasticsearch.post_document(Cluster, %Post{title: "Post"}, "posts-1")
      # => {:ok,
      # =>   %{
      # =>     "_id" => "W0tpsmIBdwcYyG50zbta",
      # =>     "_index" => "posts-1",
      # =>     "_primary_term" => 1,
      # =>     "_seq_no" => 0,
      # =>     "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
      # =>     "_type" => "_doc",
      # =>     "_version" => 1,
      # =>     "result" => "created"
      # =>   }}
  """
  @spec post_document(Cluster.t(), Document.t(), index_name) :: response
  def post_document(cluster, document, index) do
    post(cluster, document_url(document, index), Document.encode(document))
  end

  @doc """
  Same as `put_document/2`, but raises on errors.

  ## Example

      iex> Index.create_from_file(Cluster, "posts-1", "test/support/settings/posts.json")
      ...> struct = %Post{id: 123, title: "Post", author: "Author"}
      ...> Elasticsearch.put_document!(Cluster, struct, "posts-1")
      %{
        "_id" => "123",
        "_index" => "posts-1",
        "_primary_term" => 1,
        "_seq_no" => 0,
        "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
        "_type" => "_doc",
        "_version" => 1,
        "result" => "created"
      }
  """
  @spec put_document!(Cluster.t(), Document.t(), index_name) :: map | no_return
  def put_document!(cluster, document, index) do
    put!(cluster, document_url(document, index), Document.encode(document))
  end

  @doc """
  Deletes a document from a given index.

  The document must implement the `Elasticsearch.Document` protocol.

  ## Example

      iex> Index.create_from_file(Cluster, "posts-1", "test/support/settings/posts.json")
      ...> struct = %Post{id: 123, title: "Post", author: "Author"}
      ...> Elasticsearch.put_document!(Cluster, struct, "posts-1")
      ...> Elasticsearch.delete_document(Cluster, struct, "posts-1")
      {:ok,
        %{
          "_id" => "123",
          "_index" => "posts-1",
          "_primary_term" => 1,
          "_seq_no" => 1,
          "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
          "_type" => "_doc",
          "_version" => 2,
          "result" => "deleted"
        }}
  """
  @spec delete_document(Cluster.t(), Document.t(), index_name) :: response
  def delete_document(cluster, document, index) do
    delete(cluster, document_url(document, index))
  end

  @doc """
  Same as `delete_document/2`, but raises on errors.

  ## Example

      iex> Index.create_from_file(Cluster, "posts-1", "test/support/settings/posts.json")
      ...> struct = %Post{id: 123, title: "Post", author: "Author"}
      ...> Elasticsearch.put_document!(Cluster, struct, "posts-1")
      ...> Elasticsearch.delete_document!(Cluster, struct, "posts-1")
      %{
        "_id" => "123",
        "_index" => "posts-1",
        "_primary_term" => 1,
        "_seq_no" => 1,
        "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
        "_type" => "_doc",
        "_version" => 2,
        "result" => "deleted"
      }
  """
  @spec delete_document!(Cluster.t(), Document.t(), index_name) :: map | no_return
  def delete_document!(cluster, document, index) do
    delete!(cluster, document_url(document, index))
  end

  defp document_url(document, index) do
    url = "/#{index}/_doc/#{Document.id(document)}"

    if routing = Document.routing(document) do
      document_url_with_routing(url, routing)
    else
      url
    end
  end

  defp document_url_with_routing(url, routing) do
    url <>
      if url =~ ~r/\?/ do
        "&"
      else
        "?"
      end <> URI.encode_query(%{routing: routing})
  end

  @doc """
  Waits for a given Elasticsearch cluster to be available.

  It will try a given number of times, with 1sec delay between tries.
  """
  @spec wait_for_boot(Cluster.t(), integer) ::
          {:ok, map}
          | {:error, RuntimeError.t()}
          | {:error, Elasticsearch.Exception.t()}
  def wait_for_boot(cluster, tries, count \\ 0)

  def wait_for_boot(_cluster, tries, count) when count == tries do
    {
      :error,
      RuntimeError.exception("""
      Elasticsearch could not be found after #{count} tries. Make sure it's running?
      """)
    }
  end

  def wait_for_boot(cluster, tries, count) do
    with {:error, _} <- get(cluster, "/_cat/health?format=json") do
      :timer.sleep(1000)
      wait_for_boot(cluster, tries, count + 1)
    end
  end

  @doc """
  Gets the contents of a path from the Elasticsearch API.

  ## Examples

      iex> {:ok, resp} = Elasticsearch.get(Cluster, "/_cat/health?format=json")
      ...> is_list(resp)
      true

      iex> Elasticsearch.get(Cluster, "/nonexistent")
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
  @spec get(Cluster.t(), url) :: response
  @spec get(Cluster.t(), url, opts) :: response
  def get(cluster, url, opts \\ []) do
    config = Config.get(cluster)

    config
    |> do_request(:get, url, "", opts)
    |> format()
  end

  @doc """
  The same as `get/1`, but returns the response instead of a tuple. Raises on
  errors.

  ## Examples

      iex> resp = Elasticsearch.get!(Cluster, "/_cat/health?format=json")
      ...> is_list(resp)
      true

      iex> Elasticsearch.get!(Cluster, "/nonexistent")
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec get!(Cluster.t(), url) :: map | no_return
  @spec get!(Cluster.t(), url, opts) :: map | no_return
  def get!(cluster, url, opts \\ []) do
    cluster
    |> get(url, opts)
    |> unwrap!()
  end

  @doc """
  Puts data to a given Elasticsearch API path.

  ## Examples

      iex> Index.create_from_file(Cluster, "posts-1", "test/support/settings/posts.json")
      ...> Elasticsearch.put(Cluster, "/posts-1/_doc/id", %{"title" => "title", "author" => "author"})
      {:ok,
        %{
          "_id" => "id",
          "_index" => "posts-1",
          "_primary_term" => 1,
          "_seq_no" => 0,
          "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
          "_type" => "_doc",
          "_version" => 1,
          "result" => "created"
        }}

      iex> Elasticsearch.put(Cluster, "/bad/url", %{"title" => "title", "author" => "author"})
      {:error,
       %Elasticsearch.Exception{col: nil, line: nil,
        message: "Incorrect HTTP method for uri [/bad/url] and method [PUT], allowed: [POST]",
        query: nil, raw: nil, status: nil, type: nil}}
  """
  @spec put(Cluster.t(), url, data) :: response
  @spec put(Cluster.t(), url, data, opts) :: response
  def put(cluster, url, data, opts \\ []) do
    config = Config.get(cluster)

    config
    |> do_request(:put, url, data, opts)
    |> format()
  end

  @doc """
  The same as `put/2`, but returns the response instead of a tuple. Raises on
  errors.

  ## Examples

      iex> Index.create_from_file(Cluster, "posts", "test/support/settings/posts.json")
      ...> Elasticsearch.put!(Cluster, "/posts/_doc/id", %{"name" => "name", "author" => "author"})
      %{
        "_id" => "id",
        "_index" => "posts",
        "_primary_term" => 1,
        "_seq_no" => 0,
        "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
        "_type" => "_doc",
        "_version" => 1,
        "result" => "created"
      }

      iex> Elasticsearch.put!(Cluster, "/bad/url", %{"data" => "here"})
      ** (Elasticsearch.Exception) Incorrect HTTP method for uri [/bad/url] and method [PUT], allowed: [POST]
  """
  @spec put!(Cluster.t(), url, data) :: map | no_return
  @spec put!(Cluster.t(), url, data, opts) :: map | no_return
  def put!(cluster, url, data, opts \\ []) do
    cluster
    |> put(url, data, opts)
    |> unwrap!()
  end

  @doc """
  Posts data or queries to a given Elasticsearch path.

  ## Examples

      iex> Index.create_from_file(Cluster, "posts", "test/support/settings/posts.json")
      ...> query = %{"query" => %{"match_all" => %{}}}
      ...> {:ok, resp} = Elasticsearch.post(Cluster, "/posts/_search", query)
      ...> resp["hits"]["hits"]
      []
  """
  @spec post(Cluster.t(), url, data) :: response
  @spec post(Cluster.t(), url, data, opts) :: response
  def post(cluster, url, data, opts \\ []) do
    config = Config.get(cluster)

    config
    |> do_request(:post, url, data, opts)
    |> format()
  end

  @doc """
  The same as `post/1`, but returns the response. Raises on errors.

  ## Examples

      iex> Index.create_from_file(Cluster, "posts", "test/support/settings/posts.json")
      ...> query = %{"query" => %{"match_all" => %{}}}
      ...> resp = Elasticsearch.post!(Cluster, "/posts/_search", query)
      ...> is_map(resp)
      true

  Raises an error if the path is invalid or another error occurs:

      iex> query = %{"query" => %{"match_all" => %{}}}
      ...> Elasticsearch.post!(Cluster, "/nonexistent/_search", query)
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec post!(Cluster.t(), url, data) :: map | no_return
  @spec post!(Cluster.t(), url, data, opts) :: map | no_return
  def post!(cluster, url, data, opts \\ []) do
    cluster
    |> post(url, data, opts)
    |> unwrap!()
  end

  @doc """
  Deletes data at a given Elasticsearch URL.

  ## Examples

      iex> Index.create_from_file(Cluster, "posts", "test/support/settings/posts.json")
      ...> Elasticsearch.delete(Cluster, "/posts")
      {:ok, %{"acknowledged" => true}}

  It returns an error if the given resource does not exist.

      iex> Elasticsearch.delete(Cluster, "/nonexistent")
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
  @spec delete(Cluster.t(), url) :: response
  @spec delete(Cluster.t(), url, opts) :: response
  def delete(cluster, url, opts \\ []) do
    config = Config.get(cluster)

    config
    |> do_request(:delete, url, "", opts)
    |> format()
  end

  @doc """
  Same as `delete/1`, but returns the response and raises errors.

  ## Examples

      iex> Index.create_from_file(Cluster, "posts", "test/support/settings/posts.json")
      ...> Elasticsearch.delete!(Cluster, "/posts")
      %{"acknowledged" => true}

  Raises an error if the resource is invalid.

      iex> Elasticsearch.delete!(Cluster, "/nonexistent")
      ** (Elasticsearch.Exception) (index_not_found_exception) no such index
  """
  @spec delete!(Cluster.t(), url) :: map | no_return
  @spec delete!(Cluster.t(), url, opts) :: map | no_return
  def delete!(cluster, url, opts \\ []) do
    cluster
    |> delete(url, opts)
    |> unwrap!()
  end

  @doc """
  Determines whether a resource exists at a given Elasticsearch path

  ## Examples

      iex> Index.create_from_file(Cluster, "posts", "test/support/settings/posts.json")
      ...> Elasticsearch.head(Cluster, "/posts")
      {:ok, ""}

  It returns an error if the given resource does not exist.

      iex> Elasticsearch.head(Cluster, "/nonexistent")
      {:error,
      %Elasticsearch.Exception{
        col: nil,
        line: nil,
        message: "",
        query: nil,
        raw: nil,
        status: nil,
        type: nil
      }}
  """
  @spec head(Cluster.t(), url) :: response
  @spec head(Cluster.t(), url, opts) :: response
  def head(cluster, url, opts \\ []) do
    config = Config.get(cluster)

    config
    |> do_request(:head, url, "", opts)
    |> format()
  end

  @doc """
  Same as `head/1`, but returns the response and raises errors.

  ## Examples

      iex> Index.create_from_file(Cluster, "posts", "test/support/settings/posts.json")
      ...> Elasticsearch.head!(Cluster, "/posts")
      ""

  Raises an error if the resource is invalid.

      iex> Elasticsearch.head!(Cluster, "/nonexistent")
      ** (Elasticsearch.Exception)
  """
  @spec head!(Cluster.t(), url) :: map | no_return
  @spec head!(Cluster.t(), url, opts) :: map | no_return
  def head!(cluster, url, opts \\ []) do
    cluster
    |> head(url, opts)
    |> unwrap!()
  end

  defp do_request(config, method, url, data, opts) do
    start_metadata = %{config: config, method: method, url: url, data: data}

    :telemetry.span([:elasticsearch, :request], start_metadata, fn ->
      result = config.api.request(config, method, url, data, opts)
      {result, %{result: result}}
    end)
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
end
