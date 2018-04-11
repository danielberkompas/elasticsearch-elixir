defmodule Elasticsearch.Cluster do
  @type response :: {:ok, map} | {:error, Elasticsearch.Exception.t()}
  @type index_name :: String.t()
  @type url :: String.t()
  @type opts :: Keyword.t()
  @type data :: map

  # Might not need to be callbacks here
  # alias Elasticsearch.Document
  # @callback put_document(Document.t(), index_name) :: response
  # @callback put_document!(Document.t(), index_name) :: map | no_return
  # @callback delete_document(Document.t(), index_name) :: response
  # @callback delete_document!(Document.t(), index_name) :: map | no_return
  # @callback wait_for_boot(tries :: integer) :: response | {:error, RuntimeError.t()}

  @callback init(map) :: {:ok, map} | {:error, any}

  @callback get(url) :: response
  @callback get(url, opts) :: response
  @callback get!(url) :: map | no_return
  @callback get!(url, opts) :: map | no_return

  @callback put(url, data) :: response
  @callback put(url, data, opts) :: response
  @callback put!(url, data) :: map | no_return
  @callback put!(url, data, opts) :: map | no_return

  @callback post(url, data) :: response
  @callback post(url, data, opts) :: response
  @callback post!(url, data) :: map | no_return
  @callback post!(url, data, opts) :: map | no_return

  @callback delete(url) :: response
  @callback delete(url, opts) :: response
  @callback delete!(url) :: map | no_return
  @callback delete!(url, opts) :: map | no_return

  defmacro __using__(opts) do
    quote do
      use GenServer

      alias Elasticsearch.Cluster

      import Cluster, only: [format: 1, unwrap!: 1]

      @behaviour Cluster

      @impl Cluster
      def get(url, opts \\ []) do
        config = __config__()

        config
        |> config.api.request(:get, url, "", opts)
        |> format()
      end

      @impl Cluster
      def get!(url, opts \\ []) do
        url
        |> get(opts)
        |> unwrap!()
      end

      @impl Cluster
      def put(url, data, opts \\ []) do
        config = __config__()

        config
        |> config.api.request(:put, url, data, opts)
        |> format()
      end

      @impl Cluster
      def put!(url, data, opts \\ []) do
        url
        |> put(data, opts)
        |> unwrap!()
      end

      @impl Cluster
      def post(url, data, opts \\ []) do
        config = __config__()

        config
        |> config.api.request(:post, url, data, opts)
        |> format()
      end

      @impl Cluster
      def post!(url, data, opts \\ []) do
        url
        |> post(data, opts)
        |> unwrap!()
      end

      @impl Cluster
      def delete(url, opts \\ []) do
        config = __config__()

        config
        |> config.api.request(:delete, url, "", opts)
        |> format()
      end

      @impl Cluster
      def delete!(url, opts \\ []) do
        url
        |> delete(opts)
        |> unwrap!()
      end

      ###
      # GenServer
      ###

      # Cache configuration into the state of the GenServer so that
      # we aren't running potentially expensive logic to load configuration
      # on each function call.
      def start_link(config \\ []) do
        app_config =
          unquote(opts[:otp_app])
          |> Application.get_env(__MODULE__, [])
          |> Enum.into(%{})

        config = Map.merge(app_config, Enum.into(config, %{}))

        # Ensure that the configuration is validated on startup
        with {:ok, pid} <- GenServer.start_link(__MODULE__, config, name: __MODULE__),
             :ok <- GenServer.call(pid, :validate) do
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
        GenServer.call(__MODULE__, :config)
      end

      @impl GenServer
      @doc false
      def handle_call(:config, _from, config) do
        {:reply, config, config}
      end

      def handle_call(:validate, _from, config) do
        case Cluster.validate_config(config) do
          {:ok, _config} ->
            {:reply, :ok, config}

          error ->
            {:reply, error, config}
        end
      end

      defoverridable init: 1
    end
  end

  @doc false
  def validate_config(config) do
    with {:ok, _config} <-
           Vex.validate(
             config,
             url: &(is_binary(&1) && String.starts_with?(&1, "http")),
             username: [presence: [unless: &(&1[:password] == nil)]],
             password: [presence: [unless: &(&1[:username] == nil)]],
             api: [presence: true, by: &is_atom/1],
             json_library: [presence: true, by: &is_atom/1],
             bulk_page_size: [presence: true, by: &is_integer/1],
             bulk_wait_interval: [presence: true, by: &is_integer/1]
           ),
         :ok <- validate_indexes(config[:indexes] || []) do
      {:ok, config}
    end
  end

  def validate_indexes(indexes) do
    invalid =
      indexes
      |> Enum.map(&validate_index_config/1)
      |> Enum.reject(&match?({:ok, _}, &1))
      |> Enum.map(&elem(&1, 1))

    if length(invalid) == 0 do
      :ok
    else
      {:error, invalid}
    end
  end

  @doc false
  def validate_index_config(index) do
    Vex.validate(
      index,
      settings: [presence: true, by: &is_binary/1],
      store: [presence: true, by: &is_atom/1],
      sources: [presence: true, by: &Enum.map(&1, fn source -> is_atom(source) end)]
    )
  end

  @doc false
  def format({:ok, %{status_code: code, body: body}})
      when code >= 200 and code < 300 do
    {:ok, body}
  end

  def format({:ok, %{body: body}}) do
    error = Elasticsearch.Exception.exception(response: body)
    {:error, error}
  end

  def format(error), do: error

  @doc false
  def unwrap!({:ok, value}), do: value
  def unwrap!({:error, exception}), do: raise(exception)
end
