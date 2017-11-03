defmodule Elasticsearch.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elasticsearch,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Elasticsearch.Application, []}
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(env) when env in ~w(test dev)a, do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, ">= 0.0.0"},
      {:httpoison, ">= 0.0.0"},
      {:dialyze, ">= 0.0.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      main: "README",
      extras: ["README.md"]
    ]
  end
end
