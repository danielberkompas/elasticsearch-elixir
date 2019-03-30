defmodule Elasticsearch.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elasticsearch,
      description: "Elasticsearch without DSLs",
      source_url: "https://github.com/danielberkompas/elasticsearch-elixir",
      version: "1.0.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      ],
      docs: docs(),
      deps: deps(),
      package: package(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Elasticsearch.Application, []}
    ]
  end

  def package do
    [
      files: ~w(
        lib
        CHANGELOG.md
        LICENSE
        README.md
        mix.exs
        priv
      ),
      maintainers: ["Daniel Berkompas"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/danielberkompas/elasticsearch-elixir"
      }
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(env) when env in ~w(test dev)a, do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, ">= 0.0.0", optional: true},
      {:httpoison, ">= 0.0.0"},
      {:vex, "~> 0.6.0"},
      {:sigaws, "~> 0.7", optional: true},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test]},
      {:ecto, ">= 0.0.0", only: [:dev, :test]},
      {:excoveralls, ">= 0.0.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "guides/deployment/distillery.md": [title: "Distillery"],
        "guides/upgrading/0.4.x_to_0.5.x.md": [title: "0.4.x to 0.5.x"],
        "guides/upgrading/0.3.x_to_0.4.x.md": [title: "0.3.x to 0.4.x"],
        "guides/upgrading/0.2.x_to_0.3.x.md": [title: "0.2.x to 0.3.x"],
        "guides/upgrading/0.1.x_to_0.2.x.md": [title: "0.1.x to 0.2.x"]
      ],
      extra_section: "GUIDES",
      groups_for_extras: [
        Deployment: ~r/deployment/,
        Upgrading: ~r/upgrading/
      ],
      groups_for_modules: [
        API: [
          Elasticsearch,
          Elasticsearch.API,
          Elasticsearch.API.HTTP
        ],
        Config: [
          Elasticsearch.Cluster
        ],
        Indexing: [
          Elasticsearch.Index,
          Elasticsearch.Index.Bulk
        ],
        Storage: [
          Elasticsearch.DataStream,
          Elasticsearch.Document,
          Elasticsearch.Store
        ],
        Development: [
          Elasticsearch.Executable
        ]
      ]
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
