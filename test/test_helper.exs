ExUnit.start()

unless System.get_env("CI") do
  Elasticsearch.Executable.start_link("Elasticsearch", "./vendor/elasticsearch/bin/elasticsearch", 9200)
end

{:ok, _} = Elasticsearch.wait_for_boot(15)
