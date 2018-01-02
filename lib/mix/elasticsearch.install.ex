defmodule Mix.Tasks.Elasticsearch.Install do
  @moduledoc """
  FOR DEVELOPMENT USE ONLY.

  This task is provided as a convenient way to install a particular version
  of Elasticsearch for your project on a development machine.

  Use `Elasticsearch.Executable` to add the executables to your app's
  supervision tree in the Mix `:dev` environment.

  ## Example

      # Installs Elasticsearch and Kibana 5.1.1 to vendor/
      mix elasticsearch.install vendor --version 5.1.1
  """

  @doc false
  def run(args) do
    with {[{:version, version}], [location], _} <-
           OptionParser.parse(args, switches: [version: :string]) do
      download_elasticsearch(version, location)
      download_kibana(version, location)
    else
      _ ->
        Mix.raise("""
        Invalid options. See `mix help elasticsearch.install`
        """)
    end
  end

  defp download_elasticsearch(version, location) do
    name = "elasticsearch-#{version}"
    tar = "#{name}.tar.gz"

    System.cmd(
      "curl",
      ["-L", "-O", "https://artifacts.elastic.co/downloads/elasticsearch/#{tar}"],
      cd: location
    )

    unpack(tar, name, "elasticsearch", location)
  end

  defp download_kibana(version, location) do
    name =
      case :os.type() do
        {:unix, :darwin} ->
          "kibana-#{version}-darwin-x86_64"

        other ->
          Mix.raise("Unsupported system for Kibana: #{inspect(other)}")
      end

    tar = "#{name}.tar.gz"

    System.cmd(
      "curl",
      ["-L", "-O", "https://artifacts.elastic.co/downloads/kibana/#{tar}"],
      cd: location
    )

    unpack(tar, name, "kibana", location)
  end

  defp unpack(tar, name, alias, location) do
    System.cmd("tar", ["-zxvf", tar], cd: location)
    System.cmd("rm", [tar], cd: location)
    System.cmd("mv", [name, alias], cd: location)
  end
end
