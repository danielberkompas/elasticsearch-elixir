# Deploying with Distillery

Because Distillery 1-2.x does not support Mix Tasks, you must do some extra
work to use this library's hot swap feature. As shown in Distillery's
[official
documentation](https://hexdocs.pm/distillery/guides/running_migrations.html),
you will need to create a `ReleaseTasks` module.

```elixir
defmodule MyApp.ReleaseTasks do
  # OTP apps that must be started in order for the code in this module
  # to function properly.
  #
  # Don't forget about Ecto and Postgrex if you're using Ecto to load documents
  # in your Elasticsearch.Store module!
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :elasticsearch
  ]

  # Ecto repos to start, if any
  @repos Application.get_env(:my_app, :ecto_repos, [])

  # Elasticsearch clusters to start
  @clusters [MyApp.Cluster]

  # Elasticsearch indexes to build
  @indexes [:posts]

  def build_elasticsearch_indexes(_argv) do
    start_services()
    IO.puts("Building indexes...")
    Enum.each(@indexes, &Elasticsearch.Index.hot_swap(MyApp.Cluster, &1))
    stop_services()
  end

  # Ensure that all OTP apps, repos used by your Elasticsearch store,
  # and your Elasticsearch Cluster(s) are started
  defp start_services do
    IO.puts("Starting dependencies...")
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    IO.puts("Starting repos...")
    Enum.each(@repos, & &1.start_link(pool_size: 1))

    IO.puts("Starting clusters...")
    Enum.each(@clusters, & &1.start_link())
  end

  defp stop_services do
    :init.stop()
  end
end
```

Then, create a custom command in `rel/commands`:

```sh
# rel/commands/build_elasticsearch_indexes.sh
#!/bin/sh

release_ctl eval --mfa "MyApp.ReleaseTasks.build_elasticsearch_indexes/1" -- "$@"
```

Finally, set up your `rel/config.exs` file:

```elixir
release :myapp do
  ...
  set commands: [
    build_elasticsearch_indexes: "rel/commands/build_elasticsearch_indexes.sh",
  ]
end
```

Now, once you've deployed the application, you can build indexes with
`bin/myapp build_elasticsearch_indexes`.