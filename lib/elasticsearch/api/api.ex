defmodule Elasticsearch.API do
  @moduledoc """
  Defines the necessary callbacks for integrating with the Elasticsearch
  JSON API.
  """

  @type url :: String.t()
  @type data :: map | Keyword.t()
  @type opts :: Keyword.t()
  @type headers :: Keyword.t()

  @type response ::
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}

  @callback get(url, headers, opts) :: response
  @callback put(url, data, headers, opts) :: response
  @callback post(url, data, headers, opts) :: response
  @callback delete(url, headers, opts) :: response
end