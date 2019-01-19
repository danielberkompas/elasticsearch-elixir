# Elasticsearch

[![Hex.pm](https://img.shields.io/hexpm/v/elasticsearch.svg)](https://hex.pm/packages/elasticsearch)
[![Build Status](https://travis-ci.org/infinitered/elasticsearch-elixir.svg?branch=master)](https://travis-ci.org/infinitered/elasticsearch-elixir)
[![Coverage Status](https://coveralls.io/repos/github/infinitered/elasticsearch-elixir/badge.svg?branch=master)](https://coveralls.io/github/infinitered/elasticsearch-elixir?branch=master)

A simple, no-nonsense Elasticsearch library for Elixir. Highlights include:

- **No DSLs.** Interact directly with the `Elasticsearch` JSON API.
- **Zero-downtime index (re)building.** Via `Mix.Tasks.Elasticsearch.Build` task.
- **Dev Tools**. Helpers for running Elasticsearch as part of your supervision
  tree during development.

## Installation

Add `elasticsearch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elasticsearch, "~> 0.6.2"}
  ]
end
```

Then, create an `Elasticsearch.Cluster` in your application:

```elixir
defmodule MyApp.ElasticsearchCluster do
  use Elasticsearch.Cluster, otp_app: :my_app
end
```

Once you have created your cluster, add it to your application's supervision tree:

```elixir
children = [
  MyApp.ElasticsearchCluster
]
```

Finally, you can issue requests to Elasticsearch using it.

```elixir
Elasticsearch.get(MyApp.ElasticsearchCluster, "/_cat/health")
```

## Configuration

See the annotated example configuration below.

```elixir
config :my_app, MyApp.ElasticsearchCluster,
  # The URL where Elasticsearch is hosted on your system
  url: "http://localhost:9200",

  # If your Elasticsearch cluster uses HTTP basic authentication,
  # specify the username and password here:
  username: "username",
  password: "password",

  # If you want to mock the responses of the Elasticsearch JSON API
  # for testing or other purposes, you can inject a different module
  # here. It must implement the Elasticsearch.API behaviour.
  api: Elasticsearch.API.HTTP,

  # Customize the library used for JSON encoding/decoding.
  json_library: Poison, # or Jason

  # You should configure each index which you maintain in Elasticsearch here.
  # This configuration will be read by the `mix elasticsearch.build` task,
  # described below.
  indexes: %{
    # This is the base name of the Elasticsearch index. Each index will be
    # built with a timestamp included in the name, like "posts-5902341238".
    # It will then be aliased to "posts" for easy querying.
    posts: %{
      # This file describes the mappings and settings for your index. It will
      # be posted as-is to Elasticsearch when you create your index, and
      # therefore allows all the settings you could post directly.
      settings: "priv/elasticsearch/posts.json",

      # This store module must implement a store behaviour. It will be used to
      # fetch data for each source in each indexes' `sources` list, below:
      store: MyApp.ElasticsearchStore,

      # This is the list of data sources that should be used to populate this
      # index. The `:store` module above will be passed each one of these
      # sources for fetching.
      #
      # Each piece of data that is returned by the store must implement the
      # Elasticsearch.Document protocol.
      sources: [MyApp.Post],

      # When indexing data using the `mix elasticsearch.build` task,
      # control the data ingestion rate by raising or lowering the number
      # of items to send in each bulk request.
      bulk_page_size: 5000,

      # Likewise, wait a given period between posting pages to give
      # Elasticsearch time to catch up.
      bulk_wait_interval: 15_000 # 15 seconds
    }
  }
```

#### Specifying HTTPoison Options

```elixir
config :my_app, MyApp.ElasticsearchCluster,
  default_options: [
    timeout: 5_000,
    recv_timeout: 5_000,
    hackney: [pool: :pool_name]
  ]
```

## Protocols and Behaviours

#### Elasticsearch.Store

Your app must provide a `Store` module, which will fetch data to upload to
Elasticsearch. This module must implement the `Elasticsearch.Store`
behaviour.

The example below uses `Ecto`, but you can implement the behaviour on top
of any persistence layer.

```elixir
defmodule MyApp.ElasticsearchStore do
  @behaviour Elasticsearch.Store

  import Ecto.Query

  alias MyApp.Repo

  @impl true
  def stream(schema) do
    Repo.stream(schema)
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end
end
```

#### Elasticsearch.Document

Each result returned by your store must implement the `Elasticsearch.Document`
protocol.

```elixir
defimpl Elasticsearch.Document, for: MyApp.Post do
  def id(post), do: post.id
  def routing(_), do: false
  def encode(post) do
    %{
      title: post.title,
      author: post.author
    }
  end
end
```

#### Elasticsearch.API

You can plug in a different module to make API requests, as long as it
implements the `Elasticsearch.API` behaviour.

This can be used in test mode, for example:

```elixir
# config/test.exs
config :my_app, MyApp.ElasticsearchCluster,
  api: MyApp.ElasticsearchMock
```

Your mock can then stub requests and responses from Elasticsearch.

```elixir
defmodule MyApp.ElasticsearchMock do
  @behaviour Elasticsearch.API

  @impl true
  def request(_config, :get, "/posts/1", _data, _opts) do
    {:ok, %HTTPoison.Response{
      status_code: 404,
      body: %{
        "status" => "not_found"
      }
    }}
  end
end
```

## Indexing

#### Bulk

Use the `mix elasticsearch.build` task to build indexes using a zero-downtime,
hot-swap technique with Elasticsearch aliases.

```bash
# This will read the `indexes[posts]` configuration seen above, to build
# an index, `posts-123123123`, which will then be aliased to `posts`.
$ mix elasticsearch.build posts --cluster MyApp.ElasticsearchCluster
```

See the docs on `Mix.Tasks.Elasticsearch.Build` and `Elasticsearch.Index`
for more details.

#### Individual Documents

Use `Elasticsearch.put_document/3` to upload a document to a particular index.

```elixir
# MyApp.Post must implement Elasticsearch.Document
Elasticsearch.put_document(MyApp.ElasticsearchCluster, %MyApp.Post{}, "index-name")
```

To remove documents, use `Elasticsearch.delete_document/3`:

```elixir
Elasticsearch.delete_document(MyApp.ElasticsearchCluster, %MyApp.Post{}, "index-name")
```

## Querying

You can query Elasticsearch the `post/3` function:

```elixir
# Raw query
Elasticsearch.post(MyApp.ElasticsearchCluster, "/posts/_doc/_search", '{"query": {"match_all": {}}}')

# Using a map
Elasticsearch.post(MyApp.ElasticsearchCluster, "/posts/_doc/_search", %{"query" => %{"match_all" => %{}}})
```

See the official Elasticsearch [documentation](https://www.elastic.co/guide/en/elasticsearch/reference/6.x/index.html)
for how to write queries.

## Dev Tools

This package provides two utilities for developing with Elasticsearch:

- `mix elasticsearch.install`: A mix task to install Elasticsearch and Kibana
  to a folder of your choosing.

- `Elasticsearch.Executable`. Use this to start and stop Elasticsearch as part
  of your supervision tree.

  ```elixir
  children = [
    worker(Elasticsearch.Executable, [
      "Elasticsearch",
      "./vendor/elasticsearch/bin/elasticsearch", # assuming elasticsearch is in your vendor/ dir
      9200
    ], id: :elasticsearch),
    worker(Elasticsearch.Executable, [
      "Kibana",
      "./vendor/kibana/bin/kibana", # assuming kibana is in your vendor/ dir
      5601
    ], id: :kibana)
  ]
  ```

## Elasticsearch 5.x Support

As of version `0.3.0` of this client library, multiple document types are not
supported, because support for these was removed in Elasticsearch 6.x. You
can still use this library with Elasticsearch 5.x, but you must design your
indexes in the Elasticsearch 6.x style.

Read more about this in Elasticsearch's guide, ["Removal of Mapping
Types"](https://www.elastic.co/guide/en/elasticsearch/reference/6.2/removal-of-types.html).

## Documentation

[Hex Documentation](https://hexdocs.pm/elasticsearch)

Run `mix docs` to generate local documentation.

## Contributing

To contribute code to this project, you'll need to:

1. Fork the repo
2. Clone your fork
3. Run `bin/setup`
4. Create a branch
5. Commit your changes
6. Open a PR

## Premium Support

[Infinite Red](https://infinite.red) offers premium support for this library and general web &
mobile app design/development services. Get in touch [here](https://infinite.red/contact) or email us at [hello@infinite.red](mailto:hello@infinite.red).

![Infinite Red Logo](https://infinite.red/images/infinite_red_logo_colored.png)
