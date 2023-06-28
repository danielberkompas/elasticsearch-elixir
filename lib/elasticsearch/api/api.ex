defmodule Elasticsearch.API do
  @moduledoc """
  Behaviour for interacting with the Elasticsearch JSON API.
  """

  @typedoc "An HTTP method"
  @type method :: :get | :put | :post | :delete | :head

  @typedoc "The URL to request from the API"
  @type url :: String.t()

  @typedoc "A payload of data to send, relevant to :put and :post requests"
  @type data :: binary | map | Keyword.t()

  @typedoc "A keyword list of options to pass to the HTTP adapter"
  @type opts :: Keyword.t()

  @typedoc "A Req.Response struct"
  @type response :: Req.Response.t()

  @doc """
  Makes a request to an Elasticsearch JSON API URl using the given method.
  """
  @callback request(config :: Elasticsearch.Cluster.config(), method, url, data, opts) :: response
end
