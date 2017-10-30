defmodule Elasticsearch.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elasticsearch,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, ">= 0.0.0"},
      {:dialyze, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
