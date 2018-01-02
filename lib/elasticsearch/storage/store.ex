defmodule Elasticsearch.Store do
  @type source :: any
  @type data :: any
  @type offset :: integer
  @type limit :: integer

  @callback load(source, offset, limit) :: [data]
end