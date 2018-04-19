defmodule Elasticsearch.Index.Bulk do
  @moduledoc """
  Functions for creating bulk indexing requests.
  """

  alias Elasticsearch.{
    Cluster,
    DataStream,
    Document
  }

  require Logger

  @doc """
  Encodes a given variable into an Elasticsearch bulk request. The variable
  must implement `Elasticsearch.Document`.

  ## Examples

      iex> Bulk.encode(Cluster, %Post{id: "my-id"}, "my-index")
      {:ok, \"\"\"
      {"create":{"_index":"my-index","_id":"my-id"}}
      {"title":null,"author":null}
      \"\"\"}

      iex> Bulk.encode(Cluster, 123, "my-index")
      {:error,
        %Protocol.UndefinedError{description: "",
        protocol: Elasticsearch.Document, value: 123}}
  """
  @spec encode(Cluster.t(), struct, String.t()) ::
          {:ok, String.t()}
          | {:error, Error.t()}
  def encode(cluster, struct, index) do
    {:ok, encode!(cluster, struct, index)}
  rescue
    exception ->
      {:error, exception}
  end

  @doc """
  Same as `encode/3`, but returns the request and raises errors.

  ## Example

      iex> Bulk.encode!(Cluster, %Post{id: "my-id"}, "my-index")
      \"\"\"
      {"create":{"_index":"my-index","_id":"my-id"}}
      {"title":null,"author":null}
      \"\"\"

      iex> Bulk.encode!(Cluster, 123, "my-index")
      ** (Protocol.UndefinedError) protocol Elasticsearch.Document not implemented for 123. This protocol is implemented for: Post
  """
  def encode!(cluster, struct, index) do
    config = Cluster.Config.get(cluster)
    header = header(config, "create", index, struct)

    document =
      struct
      |> Document.encode()
      |> config.json_library.encode!()

    "#{header}\n#{document}\n"
  end

  defp header(config, type, index, struct) do
    attrs = %{
      "_index" => index,
      "_id" => Document.id(struct)
    }

    config.json_library.encode!(%{type => attrs})
  end

  @doc """
  Uploads all the data from the list of `sources` to the given index.
  Data for each `source` will be fetched using the configured `:store`.
  """
  @spec upload(Cluster.t(), index_name :: String.t(), Elasticsearch.Store.t(), list) ::
          :ok | {:error, [map]}
  def upload(cluster, index_name, store, sources, errors \\ [])
  def upload(_cluster, _index_name, _store, [], []), do: :ok
  def upload(_cluster, _index_name, _store, [], errors), do: {:error, errors}

  def upload(cluster, index_name, store, [source | tail] = _sources, errors) do
    config = Cluster.Config.get(cluster)

    errors =
      config
      |> DataStream.stream(source, store)
      |> Stream.map(&encode!(config, &1, index_name))
      |> Stream.chunk_every(config.bulk_page_size)
      |> Stream.map(&Elasticsearch.put(cluster, "/#{index_name}/_doc/_bulk", Enum.join(&1)))
      |> Enum.reduce(errors, &collect_errors/2)

    upload(cluster, index_name, store, tail, errors)
  end

  defp collect_errors({:ok, %{"errors" => true} = response}, errors) do
    new_errors =
      response["items"]
      |> Enum.filter(&(&1["create"]["error"] != nil))
      |> Enum.map(& &1["create"])
      |> Enum.map(&Elasticsearch.Exception.exception(response: &1))

    new_errors ++ errors
  end

  defp collect_errors({:error, error}, errors) do
    [error | errors]
  end

  defp collect_errors(_response, errors) do
    errors
  end
end
