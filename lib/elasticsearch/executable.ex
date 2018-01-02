defmodule Elasticsearch.Executable do
  @moduledoc """
  Wraps an Elasticsearch executable so it can be run as part of the Elixir
  supervision tree.

  See `Mix.Tasks.Elasticsearch.Install` to install Elasticsearch to a directory
  for your project.

  ## Example

  Add a worker to your supervision tree, like so:

      worker(Elasticsearch.Executable, [
        "Elasticsearch",
        "./vendor/elasticsearch/bin/elasticsearch",
        9200
      ], id: :elasticsearch),
  """

  use GenServer

  def start_link(name, executable, port_number) do
    GenServer.start_link(__MODULE__, [name, executable, port_number])
  end

  def init([name, executable, port_number]) do
    case System.cmd("lsof", ["-i", ":#{port_number}"]) do
      {"", _} ->
        wrap = Application.app_dir(:elasticsearch) <> "/priv/bin/wrap"
        port = Port.open({:spawn, "#{wrap} #{executable} --port #{port_number}"}, [])
        {:os_pid, os_pid} = Port.info(port, :os_pid)
        IO.puts("[info] Running #{name} with PID #{os_pid} on port #{port_number}")
        {:ok, port}

      _other ->
        IO.puts("[info] Detected #{name} already running on port #{port_number}")
        {:ok, nil}
    end
  end
end
