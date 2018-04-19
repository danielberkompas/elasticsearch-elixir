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
  end
end
