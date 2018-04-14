defmodule Elasticsearch.API.HTTP do
  @moduledoc """
  A "real" HTTP implementation of `Elasticsearch.API`.
  """

  @behaviour Elasticsearch.API

  @impl true
  def request(config, method, url, data, opts) do
    method
    |> HTTPoison.request(
      process_url(url, config),
      process_request_body(data, config),
      headers(config),
      opts ++ Map.get(config, :default_opts, [])
    )
    |> process_response(config)
  end

  # Respect absolute URLs if passed
  defp process_url("http" <> _rest = url, _config) do
    url
  end

  # On relative urls, prepend the configured base URL
  defp process_url(url, config) do
    Path.join(config.url, url)
  end

  # Converts the request body into JSON, unless it has already
  # been converted
  defp process_request_body(data, _config) when is_binary(data) do
    data
  end

  defp process_request_body(data, config) when is_map(data) do
    json_library(config).encode!(data)
  end

  # Converts the response body string from JSON into a map, if it looks like it
  # is actually JSON
  defp process_response({:ok, %{body: body} = response}, config) do
    body =
      cond do
        json?(body) -> json_library(config).decode!(body)
        true -> body
      end

    {:ok, %{response | body: body}}
  end

  defp process_response(response, _config) do
    response
  end

  defp json?(str) when is_binary(str) do
    str =~ ~r/^\{/ || str =~ ~r/^\[/
  end

  # Produces request headers for the request, based on the configuration
  defp headers(config) do
    headers = [{"Content-Type", "application/json"}] ++ Map.get(config, :default_headers, [])

    credentials = http_basic_credentials(config)

    if credentials do
      [{"Authorization", "Basic #{credentials}"} | headers]
    else
      headers
    end
  end

  defp http_basic_credentials(%{username: username, password: password}) do
    Base.encode64("#{username}:#{password}")
  end

  defp http_basic_credentials(_config) do
    nil
  end

  defp json_library(%{json_library: json_library}) do
    json_library
  end

  defp json_library(_config) do
    Poison
  end
end
