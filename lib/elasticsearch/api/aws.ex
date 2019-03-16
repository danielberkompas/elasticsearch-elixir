defmodule Elasticsearch.API.AWS do
  @moduledoc """
  A HTTP signed implementation of `Elasticsearch.API` to interact with AWS Elasticsearch Service.
  """

  @behaviour Elasticsearch.API

  @impl true
  def request(config, method, url, data, opts) do
    full_url = process_url(url, config)
    payload = process_request_body(data, config)

    method
    |> HTTPoison.request(
      full_url,
      payload,
      headers(method, full_url, data, config),
      opts ++ Map.get(config, :default_options, [])
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
  # been converted. If the data is empty, sends ""
  defp process_request_body(data, _config) when is_binary(data) do
    data
  end

  defp process_request_body(data, config) when is_map(data) and data != %{} do
    json_library(config).encode!(data)
  end

  defp process_request_body(_data, _config) do
    ""
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
  defp headers(method, full_url, data, config) do
    default_headers = Map.get(config, :default_headers)

    sign_request(method, full_url, data, config, default_headers)
  end

  defp json_library(%{json_library: json_library}), do: json_library

  defp json_library(_config), do: Poison

  defp sign_request(method, url, body, config, default_headers) when is_binary(body) do
    options = build_options(method, config, body)

    build_signed_request(url, options, default_headers)
  end

  defp sign_request(method, url, body, config, default_headers) when is_map(body) and body != %{} do
    options = build_options(method, config, json_library(config).encode!(body))

    build_signed_request(url, options, default_headers)
  end

  defp sign_request(method, url, body, config, default_headers) when body == %{} do
    options = build_options(method, config, "")

    build_signed_request(url, options, default_headers)
  end

  defp build_options(method, config, body) do
    [
      method: String.capitalize(Atom.to_string(method)),
      region: Map.get(config, :aws_region),
      service: Map.get(config, :aws_service),
      access_key: Map.get(config, :aws_access_key_id),
      secret: Map.get(config, :aws_secret_access_key),
      body: body
    ]
  end

  def build_signed_request(url, options, default_headers) do
    {:ok, signed_data, _} = Sigaws.sign_req(url, options)

    default_headers
    |> Map.merge(%{"Content-Type": "application/json"})
    |> Map.merge(signed_data)
  end
end
