defmodule ElasticsearchTest do
  use ExUnit.Case

  alias Elasticsearch.{
    Index,
    Test.Cluster
  }

  doctest Elasticsearch

  setup do
    on_exit(fn ->
      Cluster
      |> Index.starting_with("posts")
      |> elem(1)
      |> Enum.map(&Elasticsearch.delete!(Cluster, "/#{&1}"))

      Elasticsearch.delete(Cluster, "/nonexistent")
    end)
  end

  describe ".put_document/3" do
    test "routing meta-field is included if specified in Document" do
      Elasticsearch.delete(Cluster, "/posts-routing")

      assert :ok =
               Elasticsearch.Index.create_from_file(
                 Cluster,
                 "posts-routing",
                 "test/support/settings/posts.json"
               )

      assert {:ok, _} =
               Elasticsearch.put_document(
                 Cluster,
                 %Post{id: 1, title: "Example Post", author: "John Smith"},
                 "posts-routing"
               )

      # If a routing key is not provided, this will throw an {:error, _}
      #   Elasticsearch.Exception: [routing] is missing for join field [doctype]
      assert {:ok, _} =
               Elasticsearch.put_document(
                 Cluster,
                 %Comment{id: 2, body: "Example Comment", author: "Jane Smith", post_id: 1},
                 "posts-routing"
               )

      Elasticsearch.delete(Cluster, "/posts-routing")
    end
  end

  describe ".post_document/3" do
    # GitHub: https://github.com/danielberkompas/elasticsearch-elixir/issues/60
    @tag timeout: :infinity
    @tag :regression
    test "does not post ID when ID is nil" do
      Elasticsearch.delete(Cluster, "/posts-id")

      assert :ok =
               Elasticsearch.Index.create_from_file(
                 Cluster,
                 "posts-id",
                 "test/support/settings/posts.json"
               )

      assert {:ok, _} =
               Elasticsearch.post_document(
                 Cluster,
                 %Post{title: "Example Post", author: "John Smith"},
                 "posts-id"
               )

      Elasticsearch.Index.refresh!(Cluster, "posts-id")
      {:ok, index} = Elasticsearch.get(Cluster, "/posts-id/_search")

      assert get_in(index, ["hits", "hits", Access.at(0), "_id"]) != nil

      assert get_in(index, ["hits", "hits", Access.at(0), "_source"]) == %{
               "author" => "John Smith",
               "doctype" => %{"name" => "post"},
               "title" => "Example Post"
             }

      Elasticsearch.delete(Cluster, "/posts-id")
    end
  end
end
