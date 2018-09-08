defmodule Elasticsearch.ExceptionTest do
  use ExUnit.Case

  alias Elasticsearch.Exception

  describe ".exception/1" do
    test "handles errors with type" do
      assert %Exception{type: "type", message: nil, query: "query"} =
               Exception.exception(
                 response: %{"error" => %{"type" => "type"}},
                 query: "query"
               )

      assert %Exception{type: "root_cause", message: "message", query: "query"} =
               Exception.exception(
                 response: %{
                   "error" => %{
                     "root_cause" => [%{"type" => "root_cause"}],
                     "reason" => "message"
                   }
                 },
                 query: "query"
               )

      assert %Exception{message: "message", query: "query"} =
               Exception.exception(response: "message", query: "query")
    end

    # See issue: https://github.com/infinitered/elasticsearch-elixir/issues/28
    @tag :regression
    test "understands the not_found error" do
      assert %Exception{type: "not_found", message: nil, query: nil} =
               Exception.exception(
                 response: %{
                   "_id" => "54",
                   "_index" => "listings-1525371175",
                   "_primary_term" => 1,
                   "_seq_no" => 42,
                   "_shards" => %{"failed" => 0, "successful" => 1, "total" => 2},
                   "_type" => "_doc",
                   "_version" => 14,
                   "result" => "not_found"
                 },
                 query: nil
               )
    end

    # See issue: https://github.com/infinitered/elasticsearch-elixir/issues/33
    @tag :regression
    test "understands the document_not_found error" do
      assert %Exception{type: "document_not_found", message: nil, query: nil} =
               Exception.exception(
                 response: %{
                   "_id" => "123",
                   "_index" => "index-name",
                   "_type" => "_doc",
                   "found" => false
                 },
                 query: nil
               )
    end

    # See issue: https://github.com/infinitered/elasticsearch-elixir/issues/39
    @tag :regression
    test "handles arbitrary error maps" do
      assert %Exception{type: nil, message: nil, query: nil, raw: %{"message" => nil}} =
               Exception.exception(%{
                 response: %{"message" => nil},
                 query: nil
               })

      assert %Exception{
               type: nil,
               message: "Unable to connect to the server.",
               query: nil,
               raw: %{"message" => "Unable to connect to the server.", "ok" => false}
             } =
               Exception.exception(%{
                 response: %{"message" => "Unable to connect to the server.", "ok" => false},
                 query: nil
               })
    end
  end
end
