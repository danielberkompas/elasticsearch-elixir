defmodule Elasticsearch.Cluster.ConfigTest do
  use ExUnit.Case

  alias Elasticsearch.Cluster
  alias Elasticsearch.Cluster.Config

  describe ".build/3" do
    test "uses simple values" do
      assert %{username: "username", password: "password", port: 1234} =
               Config.build(:elasticsearch, Cluster, %{
                 username: "username",
                 password: "password",
                 port: 1234
               })
    end

    test "fetches settings from environment variables" do
      set_envs(%{
        "ELASTICSEARCH_USERNAME" => "username",
        "ELASTICSEARCH_PASSWORD" => "password",
        "ELASTICSEARCH_PORT" => "1234"
      })

      assert %{username: "username", password: "password", port: 1234} =
               Config.build(:elasticsearch, Cluster, %{
                 username: {:system, "ELASTICSEARCH_USERNAME"},
                 password: {:system, "ELASTICSEARCH_PASSWORD"},
                 port: {:system, :integer, "ELASTICSEARCH_PORT"}
               })
    end

    test "prefers environment variable over the default value" do
      set_envs(%{
        "ELASTICSEARCH_USERNAME" => "username",
        "ELASTICSEARCH_PASSWORD" => "password",
        "ELASTICSEARCH_PORT" => "1234"
      })

      assert %{username: "username", password: "password", port: 1234} =
               Config.build(:elasticsearch, Cluster, %{
                 username: {:system, "ELASTICSEARCH_USERNAME", "other_username"},
                 password: {:system, "ELASTICSEARCH_PASSWORD", "other_password"},
                 port: {:system, :integer, "ELASTICSEARCH_PORT", 4321}
               })
    end

    test "falls back to default value if environment variable is not set" do
      assert %{username: "username", password: "password", port: 1234} =
               Config.build(:elasticsearch, Cluster, %{
                 username: {:system, "ELASTICSEARCH_USERNAME", "username"},
                 password: {:system, "ELASTICSEARCH_PASSWORD", "password"},
                 port: {:system, :integer, "ELASTICSEARCH_PORT", 1234}
               })
    end

    test "falls back to nil if neither environment variable nor default value are set" do
      assert %{username: nil, password: nil, port: nil} =
               Config.build(:elasticsearch, Cluster, %{
                 username: {:system, "ELASTICSEARCH_USERNAME"},
                 password: {:system, "ELASTICSEARCH_PASSWORD"},
                 port: {:system, :integer, "ELASTICSEARCH_PORT"}
               })
    end
  end

  defp set_envs(envs) do
    for {key, value} <- envs do
      System.put_env(key, value)
    end

    on_exit(fn ->
      for {key, _value} <- envs do
        System.delete_env(key)
      end
    end)
  end
end
