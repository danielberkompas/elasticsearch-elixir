defmodule Elasticsearch.API.HTTPTest do
  use ExUnit.Case

  alias Elasticsearch.API.HTTP

  describe ".request/5" do
    test "respects absolute URLs" do
      assert {:ok, %HTTPoison.Response{body: body}} =
               HTTP.request(%{}, :get, "http://localhost:9200/_cat/health", "", [])

      assert is_binary(body)
    end

    test "handles HTTP errors" do
      assert {:error, %HTTPoison.Error{}} =
               HTTP.request(%{}, :get, "http://localhost:9999/nonexistent", "", [])
    end
  end
end
