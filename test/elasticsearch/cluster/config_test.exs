defmodule Elasticsearch.Cluster.ConfigTest do
  use ExUnit.Case

  alias Elasticsearch.Cluster.Config

  describe ".build/2" do
    test "handles nil as first argument" do
      assert %{key: "value"} = Config.build(nil, %{key: "value"})
    end
  end
end
