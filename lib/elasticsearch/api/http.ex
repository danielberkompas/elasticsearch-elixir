defmodule Elasticsearch.API.HTTP do
  @moduledoc """
  An HTTP implementation of `Elasticsearch.API`.
  """

  @behaviour Elasticsearch.API

  use HTTPoison.Base

  alias Elasticsearch.Config

  ###
  # HTTPoison Callbacks
  ###

  @doc false
  def process_url(url) do
    Config.url <> url
  end

  def process_request_headers(_headers) do
    headers = [{"Content-Type", "application/json"}]

    credentials = Config.http_basic_credentials()

    if credentials do
      [{"Authorization", "Basic #{credentials}"} | headers]
    else
      headers
    end
  end

  @doc false
  def process_request_body(string) when is_binary(string), do: string
  def process_request_body(map) when is_map(map) do
    Poison.encode!(map)
  end

  @doc false
  def process_response_body(body) do
    if json?(body) do
      Poison.decode!(body)
    else
      body
    end
  end

  defp json?(str) do
    str =~ ~r/^\{/ || str =~ ~r/^\[/
  end
end
