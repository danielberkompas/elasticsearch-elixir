defmodule Elasticsearch.Store do
  @moduledoc """
  A behaviour for fetching data to index using a streaming strategy.
  """

  @doc """
  Returns a stream of the given datasource.

  ## Example

      def stream(Post) do
        Repo.stream(Post)
      end
  """
  @callback stream(any) :: Stream.t()

  @doc """
  Returns a transaction wrapper to execute the stream returned by `stream/1`
  within. This is required when using Ecto.

  ## Example

      def transaction(fun) do
        {:ok, result} = Repo.transaction(fun, timeout: :infinity)
        result
      end

  If you are not using Ecto and do not require transactions, simply call the
  function passed as a parameter.

      def transaction(fun) do
        fun.()
      end
  """
  @callback transaction(fun) :: any
end
