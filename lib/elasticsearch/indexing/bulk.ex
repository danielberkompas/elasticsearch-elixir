defmodule Elasticsearch.Index.Bulk do
  @moduledoc """
  Functions for creating bulk indexing requests.
  """

  alias Elasticsearch.{
    DataStream,
    Document
  }

  require Logger

  @doc """
  Encodes a given variable into an Elasticsearch bulk request. The variable
  must implement `Elasticsearch.Document`.

  ## Examples

      iex> Bulk.encode(%Post{id: "my-id"}, "my-index")
      {:ok, \"\"\"
      {"create":{"_type":"post","_index":"my-index","_id":"my-id"}}
      {"title":null,"author":null}
      \"\"\"}

      iex> Bulk.encode(123, "my-index")
      {:error,
        %Protocol.UndefinedError{description: "",
        protocol: Elasticsearch.Document, value: 123}}
  """
  @spec encode(struct, String.t()) ::
          {:ok, String.t()}
          | {:error, Error.t()}
  def encode(struct, index) do
    {:ok, encode!(struct, index)}
  rescue
    exception ->
      {:error, exception}
  end

  @doc """
  Same as `encode/1`, but returns the request and raises errors.

  ## Example

      iex> Bulk.encode!(%Post{id: "my-id"}, "my-index")
      \"\"\"
      {"create":{"_type":"post","_index":"my-index","_id":"my-id"}}
      {"title":null,"author":null}
      \"\"\"
      
      iex> Bulk.encode!(123, "my-index")
      ** (Protocol.UndefinedError) protocol Elasticsearch.Document not implemented for 123. This protocol is implemented for: Post
  """
  def encode!(struct, index) do
    header = header("create", index, struct)

    document =
      struct
      |> Document.encode()
      |> Poison.encode!()

    "#{header}\n#{document}\n"
  end

  @doc """
  Uploads all the data from the list of `sources` to the given index.
  Data for each `source` will be fetched using the configured `:store`.
  """
  @spec upload(String.t(), Elasticsearch.Store.t(), list) :: :ok | {:error, [map]}
  def upload(index_name, store, sources, errors \\ [])
  def upload(_index_name, _store, [], []), do: :ok
  def upload(_index_name, _store, [], errors), do: {:error, errors}

  def upload(index_name, store, [source | tail] = _sources, errors) do
    errors =
      source
      |> DataStream.stream(store)
      |> Stream.map(&encode!(&1, index_name))
      |> Stream.chunk_every(config()[:bulk_page_size])
      |> Stream.map(&Elasticsearch.put("/#{index_name}/_bulk", Enum.join(&1)))
      |> Enum.reduce(errors, &collect_errors/2)

    upload(index_name, store, tail, errors)
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

  defp header(type, index, struct) do
    attrs = %{
      "_index" => index,
      "_type" => Document.type(struct),
      "_id" => Document.id(struct)
    }

    header =
      %{}
      |> Map.put(type, attrs)
      |> put_parent(type, struct)

    Poison.encode!(header)
  end

  defp put_parent(header, type, struct) do
    parent = Document.parent(struct)

    if parent do
      put_in(header[type]["_parent"], parent)
    else
      header
    end
  end

  defp config do
    Application.get_all_env(:elasticsearch)
  end
end
