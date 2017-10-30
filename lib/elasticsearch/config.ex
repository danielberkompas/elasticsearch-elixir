defmodule Elasticsearch.Config do
  @moduledoc """
  Conveniences for fetching configuration values for `Elasticsearch`.
  """

  alias Elasticsearch.DataLoader

  @doc """
  Returns the configured Elasticsearch URL.

  ## Configuration

      config :elasticsearch,
        url: "http://localhost:9200"

  System tuples are also supported:

      config :elasticsearch,
        url: {:system, "ELASTICSEARCH_URL"}

  ## Example

      iex> Config.url()
      "http://localhost:9200"
  """
  @spec url :: String.t
  def url do
    from_env(:elasticsearch, :url)
  end

  @doc """
  Returns HTTP basic credential header contents based on the configured
  `:username` and `:password`.

  ## Configuration
  
      config :elasticsearch,
        username: "username",
        password: "password"

  System tuples are also supported:

      config :elasticsearch,
        username: {:system, "ELASTICSEARCH_USERNAME"},
        password: {:system, "ELASTICSEARCH_PASSWORD"}

  ## Example

      iex> Config.http_basic_credentials()
      "dXNlcm5hbWU6cGFzc3dvcmQ="
  """
  @spec http_basic_credentials :: String.t | nil
  def http_basic_credentials do
    username = from_env(:elasticsearch, :username)
    password = from_env(:elasticsearch, :password)

    if username && password do
      Base.encode64("#{username}:#{password}")
    end
  end

  @doc """
  Generates a name for an index that will be aliased to a given `alias`.
  Similar to migrations, the name will contain a timestamp.

  ## Example

      Config.build_index_name("main")
      # => "main-1509581256"
  """
  @spec build_index_name(String.t) :: String.t
  def build_index_name(alias) do
    "#{alias}-#{system_timestamp()}"
  end

  @doc """
  Gets the full configuration for a given index.

  ## Configuration

      config :elasticsearch,
        indexes: %{
          index1: %{
            alias: "index1_alias",
            schema: "priv/elasticsearch/index1.json",
            sources: [Type1]
          }
        }

  ## Example
  
      iex> Config.config_for_index(:index1)
      %{
         alias: "index1_alias",
         schema: "priv/elasticsearch/index1.json",
         sources: [Type1]
       }
  """
  @spec config_for_index(atom) :: 
    %{alias: String.t, schema: String.t, sources: [DataLoader.source]} | 
    nil
  def config_for_index(index) do
    all()[:indexes][index]
  end

  def all do
    Application.get_all_env(:elasticsearch)
  end

  @doc """
  A light wrapper around `Application.get_env/2`, providing automatic support for
  `{:system, "VAR"}` tuples.
  """
  @spec from_env(atom, atom, any) :: any
  def from_env(otp_app, key, default \\ nil)
  def from_env(otp_app, key, default) do
    otp_app
    |> Application.get_env(key, default)
    |> read_from_system(default)
  end

  defp read_from_system({:system, env}, default), do: System.get_env(env) || default
  defp read_from_system(value, _default), do: value

  defp system_timestamp do
    DateTime.to_unix(DateTime.utc_now)
  end
end
