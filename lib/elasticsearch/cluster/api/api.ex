defmodule Elasticsearch.Cluster.API do
  @moduledoc """
  Defines the necessary callbacks for integrating with the Elasticsearch
  JSON API.
  """

  @type url :: String.t()
  @type data :: map | Keyword.t()
  @type opts :: Keyword.t()
  @type config :: map
  @type method :: :get | :put | :post | :delete

  @type response ::
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}

  @callback request(config, method, url, data, opts) :: response
end
