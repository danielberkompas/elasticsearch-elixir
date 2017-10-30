defmodule Elasticsearch.Query do
  @moduledoc """
  Represents an Elasticsearch query.

  ## Example
  
      %Elasticsearch.Query{
        indexes: [:index1, :index2],
        types: [:type1, :type2],
        query: %{
          # Use regular Elasticsearch queries here, straight out of the
          # Elasticsearch documentation, just converted to Elixir map syntax.
          "query" => %{
            "term" => %{
              "field" => "value"
            }
          }
        }
      }
  """

  alias __MODULE__

  @enforce_keys [:indexes, :types, :query]

  defstruct indexes: [],
            types: [],
            query: %{}

  @type t :: %Query{
    indexes: [atom],
    types: [atom],
    query: map
  }

  @doc """
  Returns the Elasticsearch API path a given query should POST to. Respects
  aliases for indexes.

  ## Example
  
      iex> query = %Elasticsearch.Query{
      ...>   indexes: [:index1, :index2],
      ...>   types: [:type1, :type2],
      ...>   query: %{"query" => %{}}
      ...> }
      ...> Query.url(query)
      "/index1_alias,index2_alias/type1,type2/_search"
  """
  @spec url(Query.t) :: String.t
  def url(query) do
    indexes =
      query.indexes
      |> Enum.map(&(config()[&1][:alias]))
      |> Enum.join(",")

    types = Enum.join(query.types, ",")

    "/#{indexes}/#{types}/_search"
  end

  @doc """
  Converts a query to a string that can be copy/pasted into Kibana for manual
  testing.

  ## Example
  
      iex> query = %Elasticsearch.Query{
      ...>   indexes: [:index1, :index2],
      ...>   types: [:type1, :type2],
      ...>   query: %{
      ...>     "query" => %{
      ...>       "term" => %{ "field1" => "value" }
      ...>     }
      ...>   }
      ...> }
      ...> Query.to_string(query)
      \"\"\"
      POST /index1_alias,index2_alias/type1,type2/_search
      {
        "query": {
          "term": {
            "field1": "value"
          }
        }
      }
      \"\"\"
  """
  @spec to_string(Query.t) :: String.t
  def to_string(%Query{} = query) do
    """
    POST #{url(query)}
    #{Poison.encode!(query.query, pretty: true)}
    """
  end

  defp config do
    Application.get_env(:elasticsearch, :indexes)
  end
end
