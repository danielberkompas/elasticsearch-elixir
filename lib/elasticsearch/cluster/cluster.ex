defmodule Elasticsearch.Cluster do
  @moduledoc """
  Defines and holds configuration for your Elasticsearch cluster.

      defmodule MyApp.ElasticsearchCluster do
        use Elasticsearch.Cluster
      end

  Once you have created your cluster, add it to your application's supervision tree:

      children = [
        MyApp.ElasticsearchCluster
      ]

  Finally, you can issue requests to Elasticsearch using it.

      Elasticsearch.get(MyApp.ElasticsearchCluster, "/_cat/health")

  ## Configuration

  Clusters can be configured in several ways.

  #### Via Mix

  Clusters can read configuration from the mix config, if you pass the
  `:otp_app` option:

      defmodule MyApp.ElasticsearchCluster do
        use Elasticsearch.Cluster, otp_app: :my_app
      end

      # In your config/config.exs...
      config :my_app, MyApp.ElasticsearchCluster,
        url: "http://localhost:9200",
        # ...

  #### Via `init/1`

  When a cluster starts, you can override its configuration via the `init/1`
  callback. This is a good place to read from environment variables.

      defmodule MyApp.ElasticsearchCluster do
        use Elasticsearch.Cluster

        def init(config) do
          config =
            config
            |> Map.put(:url, System.get_env("ELASTICSEARCH_URL"))
            # ...

          {:ok, config}
        end
      end

  #### Via `start_link/1`

  You can also pass configuration into the cluster directly when you start it
  with `start_link/1`.

      MyApp.Elasticsearch.start_link(url: "http://localhost:9200", ...)

  ### Configuration Options

  The following options are available for configuration.

  * `:url` - The URL at which the Elasticsearch cluster is available.

  * `:api` - The API module to use to communicate with Elasticsearch. Must implement the
    `Elasticsearch.API` behaviour.

  * `:bulk_page_size` - When creating indexes via bulk upload, how many documents to include
    per request.

  * `:bulk_wait_interval` - The number of milliseconds to wait between bulk upload requests.

  * `:indexes` - A map of indexes. Used by `mix elasticsearch.build` to build indexes.
      * `:settings`: The file path of the JSON settings for the index.
      * `:store`: An `Elasticsearch.Store` module to use to load data for the index.
      * `:sources`: A list of sources you want to load for this index.

  * `:json_library` (Optional) - The JSON library to use. (E.g. `Poison` or `Jason`)

  * `:username` (Optional) - The HTTP Basic username for the Elasticsearch endpoint, if any.

  * `:password` (Optional) - The HTTP Basic password for the Elasticsearch endpoint, if any.

  * `:default_headers` (Optional) - A list of default headers to send with the each request.

  * `:default_options` (Optional) - A list of default HTTP adapter options to send with
    each request.

  ### Configuration Example

      %{
        api: Elasticsearch.API.HTTP,
        json_library: Poison,
        url: "http://localhost:9200",
        username: "username",
        password: "password",
        default_headers: [{"authorization", "custom-value"}],
        default_options: [ssl: [{:versions, [:'tlsv1.2']}],
        indexes: %{
          posts: %{
            settings: "priv/elasticsearch/posts.json",
            store: MyApp.ElasticsearchStore,
            sources: [MyApp.Post],
            bulk_page_size: 5000,
            bulk_wait_interval: 5000
          }
        }
      }
  """

  alias Elasticsearch.Cluster.Config

  @typedoc """
  Defines valid configuration for a cluster.
  """
  @type config :: %{
          :url => String.t(),
          :api => module,
          optional(:json_library) => module,
          optional(:username) => String.t(),
          optional(:password) => String.t(),
          optional(:default_headers) => [{String.t(), String.t()}],
          optional(:default_options) => Keyword.t(),
          optional(:indexes) => %{
            optional(atom) => %{
              :settings => Path.t(),
              :store => module,
              :sources => [module],
              :bulk_page_size => integer,
              :bulk_wait_interval => integer
            }
          }
        }

  @typedoc """
  A cluster is either a module defined with `Elasticsearch.Cluster`, or a
  map that has all the required configuration keys.
  """
  @type t :: module | config

  @doc false
  defmacro __using__(opts) do
    quote do
      use GenServer

      @table_name :"#{__MODULE__}.Config"

      alias Elasticsearch.Cluster.Config

      # Cache configuration into the state of the GenServer so that
      # we aren't running potentially expensive logic to load configuration
      # on each function call.
      def start_link(config \\ []) do
        config = Config.build(unquote(opts[:otp_app]), __MODULE__, config)

        # Ensure that the configuration is validated on startup
        with {:ok, pid} <- GenServer.start_link(__MODULE__, config, name: __MODULE__),
             :ok <- GenServer.call(pid, :validate) do
          # Ensure that the configuration is saved
          GenServer.call(pid, :save_config, 10_000)

          {:ok, pid}
        else
          error ->
            GenServer.stop(__MODULE__)
            error
        end
      end

      @impl GenServer
      def init(config), do: {:ok, config}

      @doc false
      def __config__ do
        Elasticsearch.Cluster.read_config(@table_name)
      end

      @impl GenServer
      @doc false
      def handle_call(:config, _from, config) do
        {:reply, config, config}
      end

      def handle_call(:validate, _from, config) do
        case Config.validate(config) do
          {:ok, _config} ->
            {:reply, :ok, config}

          error ->
            {:reply, error, config}
        end
      end

      @impl GenServer
      def handle_call(:save_config, _from, config) do
        Elasticsearch.Cluster.save_config(@table_name, config)
        {:reply, :ok, config}
      end

      defoverridable init: 1
    end
  end

  @doc false
  def save_config(table_name, config) do
    if :ets.info(table_name) == :undefined do
      :ets.new(table_name, [:named_table, :protected])
    end

    :ets.insert(table_name, {:config, config})
  end

  @doc false
  def read_config(table_name) do
    case :ets.lookup(table_name, :config) do
      [{:config, config} | _] ->
        config

      _ ->
        :error
    end
  end
end
