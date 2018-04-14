defmodule Elasticsearch.ExecutableTest do
  use ExUnit.Case, async: false

  alias Elasticsearch.Executable

  import ExUnit.CaptureIO

  defp elasticsearch do
    case System.cmd("which", ["elasticsearch"]) do
      {"", _} ->
        "vendor/elasticsearch/bin/elasticsearch"

      {path, 0} ->
        path
    end
  end

  describe ".start_link/3" do
    test "starts the executable if it isn't running" do
      output =
        capture_io(fn ->
          assert {:ok, pid} = Executable.start_link("Elasticsearch", elasticsearch(), 9201)
          GenServer.stop(pid)
        end)

      assert output =~ "[info] Running Elasticsearch with PID"
      assert output =~ "on port 9201"
    end

    test "does nothing if executable is already running" do
      output =
        capture_io(fn ->
          assert {:ok, pid} = Executable.start_link("Elasticsearch", elasticsearch(), 9200)
          GenServer.stop(pid)
        end)

      assert output =~ "[info] Detected Elasticsearch already running on port 9200"
    end
  end
end
