defmodule Elasticsearch.Exception do
  @moduledoc """
  Represents an Elasticsearch exception raised while executing a query.
  """

  alias __MODULE__

  @keys [
    :status,
    :line,
    :col,
    :message,
    :type,
    :query,
    :raw
  ]

  @enforce_keys @keys
  defexception @keys

  def exception(opts \\ []) do
    attrs = build(opts[:response], opts[:query])
    struct(Exception, attrs)
  end

  def message(exception) do
    type = if exception.type, do: "(#{exception.type})"
    msg = if exception.message, do: exception.message

    [type, msg]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp build(%{"error" => error} = response, query) when is_map(error) do
    [
      status: response["status"],
      line: get_in(response, ["error", "line"]),
      col: get_in(response, ["error", "col"]),
      message: get_in(response, ["error", "reason"]),
      type: type(response),
      raw: response,
      query: query
    ]
  end

  defp build(%{"error" => error}, query) when is_binary(error) do
    binary_error(error, query)
  end

  defp build(%{"result" => type}, query) do
    [
      status: nil,
      line: nil,
      col: nil,
      message: nil,
      type: type,
      query: query
    ]
  end

  defp build(%{"found" => false}, query) do
    [
      status: nil,
      line: nil,
      col: nil,
      message: nil,
      type: "document_not_found",
      query: query
    ]
  end

  defp build(error, query) when is_binary(error) do
    binary_error(error, query)
  end

  defp binary_error(error, query) do
    [
      status: nil,
      line: nil,
      col: nil,
      message: error,
      type: nil,
      query: query
    ]
  end

  defp type(%{"error" => %{"root_cause" => causes}}) do
    get_in(causes, [Access.at(0), "type"])
  end

  defp type(%{"error" => %{"type" => type}}) do
    type
  end
end
