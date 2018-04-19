defmodule Elasticsearch.IndexTest do
  use Elasticsearch.DataCase, async: false

  alias Elasticsearch.{
    Index,
    Test.Cluster
  }

  doctest Elasticsearch.Index

  defmodule ErrorAPI do
    @behaviour Elasticsearch.API

    @impl true
    def request(_config, :get, _url, _data, _opts) do
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: [%{"index" => "index-name"}]
       }}
    end

    def request(_config, :delete, _url, _data, _opts) do
      {:ok,
       %HTTPoison.Response{
         status_code: 404,
         body: "index not found"
       }}
    end
  end

  setup do
    for index <- ["posts"] do
      Elasticsearch.delete(Cluster, "/#{index}*")
    end
  end

  describe ".clean_starting_with/3" do
    test "handles errors" do
      assert {:error, [%Elasticsearch.Exception{message: "index not found"}]} =
               Cluster
               |> Elasticsearch.Cluster.Config.get()
               |> Map.put(:api, ErrorAPI)
               |> Index.clean_starting_with("index", 0)
    end
  end
end
