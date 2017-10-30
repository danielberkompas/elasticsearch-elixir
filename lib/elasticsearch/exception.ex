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
    :query
  ]

  @enforce_keys @keys
  defexception @keys

  def exception(opts \\ []) do
    %Exception{
      status: opts[:response]["status"],
      line: get_in(opts[:response], ["error", "line"]),
      col: get_in(opts[:response], ["error", "col"]),
      message: get_in(opts[:response], ["error", "reason"]),
      type: get_in(opts[:response], ["error", "root_cause", Access.at(0), "type"]),
      query: opts[:query]
    }
  end

  def message(exception) do
    """
    (#{exception.type}) #{exception.message}

    #{inspect(exception.query)}
    """
  end
end
