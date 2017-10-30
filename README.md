# Elasticsearch

A simple, no-nonsense Elasticsearch library for Elixir. Highlights include:

- **No DSLs.** Interact directly with the `Elasticsearch` JSON API.
- **Zero-downtime index (re)building.** Via `Mix.Tasks.Elasticsearch.Build` task.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elasticsearch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elasticsearch, "~> 0.1.0"}
  ]
end
```

## Configuration

See the annotated example configuration below.

```elixir
config :elasticsearch,
  # The URL where Elasticsearch is hosted on your system
  url: "http://localhost:9200", # or {:system, "ELASTICSEARCH_URL"}

  # If your Elasticsearch cluster uses HTTP basic authentication,
  # specify the username and password here:
  username: "username", # or {:system, "ELASTICSEARCH_USERNAME"}
  password: "password", # or {:system, "ELASTICSEARCH_PASSWORD"}

  # When indexing data using the `mix elasticsearch.build` task,
  # control the data ingestion rate by raising or lowering the number
  # of items to send in each bulk request.
  bulk_page_size: 5000,

  # Likewise, wait a given period between posting pages to give
  # Elasticsearch time to catch up.
  bulk_wait_interval: 15_000, # 15 seconds

  # This loader module must implement the Elasticsearch.DataLoader
  # behaviour. It will be used to fetch data for each source in each
  # indexes' `sources` list, below:
  loader: MyApp.ElasticsearchLoader,

  # If you want to mock the responses of the Elasticsearch JSON API
  # for testing or other purposes, you can inject a different module
  # here. It must implement the Elasticsearch.API behaviour.
  api_module: Elasticsearch.API.HTTP,

  # You should configure each index which you maintain in Elasticsearch here.
  indexes: %{
    # `:cities` becomes the Elixir name for this index, which you'll use in
    # queries, etc.
    cities: %{
      # This is the base name of the Elasticsearch index. Each index will be
      # built with a timestamp included in the name, like "cities-5902341238".
      # It will then be aliased to "cities" for easy querying.
      alias: "cities",

      # This file describes the mappings and settings for your index. It will
      # be posted as-is to Elasticsearch when you create your index, and
      # therefore allows all the settings you could post directly.
      schema: "priv/elasticsearch/cities.json",

      # This is the list of data sources that should be used to populate this
      # index. The `:loader` module above will be passed each one of these
      # sources for fetching.
      #
      # Each piece of data that is returned by the loader must implement the
      # Elasticsearch.Document protocol.
      sources: [Type1]
    }
  }
```

## Querying

You can query Elasticsearch using raw requests, or with the help of 
the `Elasticsearch.Query` struct.

```elixir
# Raw query
Elasticsearch.post("/cities/city/_search", '{"query": {"match_all": {}}}')

# Using a map
Elasticsearch.post("/cities/city/_search", %{"query" => %{"match_all" => %{}}})

# Using a query
query = %Elasticsearch.Query{
  indexes: [:cities],
  types: [:city],
  query: %{
    "query" => %{
      "match_all" => %{}
    }
  }
}

Elasticsearch.execute(query)
```

TODOS:

- [ ] Write tests
- [ ] Update documentation in `Elasticsearch` module
- [ ] Update documentation in `mix elasticsearch.build` task
- [ ] Document how to mock Elasticsearch for testing
- [ ] Push to IR owned repo
- [ ] Prepare for publishing as hex package
- [ ] Update README
- [ ] Spec for `--append` option

