ExUnit.start()
Elasticsearch.Test.Repo.start_link()

port_number = 9200
url = "http://#{System.get_env("ELASTICSEARCH_HOST", "localhost")}:#{port_number}"

{:ok, _} = Elasticsearch.Test.Cluster.start_link(%{url: url})
{:ok, _} = Elasticsearch.wait_for_boot(Elasticsearch.Test.Cluster, 30)
