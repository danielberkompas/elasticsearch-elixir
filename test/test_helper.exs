ExUnit.start()
Elasticsearch.Test.Repo.start_link()

port_number = 9200
url = "http://localhost:#{port_number}"

unless System.get_env("CI") do
  Elasticsearch.Executable.start_link(
    "Elasticsearch",
    "./vendor/elasticsearch/bin/elasticsearch",
    port_number
  )
end

{:ok, _} = Elasticsearch.Test.Cluster.start_link(%{url: url})
{:ok, _} = Elasticsearch.wait_for_boot(Elasticsearch.Test.Cluster, 30)
