defmodule Elasticsearch.API.HTTPTest do
  use ExUnit.Case

  alias Elasticsearch.API.HTTP

  describe ".request/5" do
    test "respects absolute URLs" do
      assert {:ok, %HTTPoison.Response{body: body}} =
               HTTP.request(
                 %{},
                 :get,
                 "http://#{System.get_env("ELASTICSEARCH_HOST", "localhost")}:9200/_cat/health",
                 "",
                 []
               )

      assert is_binary(body)
    end

    test "handles HTTP errors" do
      assert {:error, %HTTPoison.Error{}} =
               HTTP.request(
                 %{},
                 :get,
                 "http://#{System.get_env("ELASTICSEARCH_HOST", "localhost")}:9999/nonexistent",
                 "",
                 []
               )
    end

    # See https://github.com/danielberkompas/elasticsearch-elixir/issues/81
    @tag :regression
    test "handles timeouts" do
      assert {:error, %HTTPoison.Error{reason: :timeout}} =
               HTTP.request(
                 %{},
                 :get,
                 "http://#{System.get_env("ELASTICSEARCH_HOST", "localhost")}:9200/_cat/health",
                 "",
                 recv_timeout: 0
               )
    end
  end
end
