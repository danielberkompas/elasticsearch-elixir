defmodule Elasticsearch.Cluster.Config do
  @moduledoc false

  def get(cluster) when is_atom(cluster) do
    cluster.__config__()
  end

  def get(config) when is_map(config) or is_list(config) do
    Enum.into(config, %{})
  end

  @doc false
  def build(nil, config) do
    Enum.into(config, %{})
  end

  def build(otp_app, module, config) do
    config = Enum.into(config, %{})

    from_app =
      otp_app
      |> Application.get_env(module, [])
      |> Enum.into(%{})

    Map.merge(from_app, config)
  end

  @doc false
  def validate(config) do
    with {:ok, config} <-
           Vex.validate(
             config,
             url: &(is_binary(&1) && String.starts_with?(&1, "http")),
             username: [presence: [unless: &(&1[:password] == nil)]],
             password: [presence: [unless: &(&1[:username] == nil)]],
             api: [presence: true, by: &is_module/1],
             json_library: [by: &(is_nil(&1) || is_module(&1))]
           ),
         :ok <- validate_indexes(config[:indexes] || %{}) do
      {:ok, config}
    else
      {:error, errors} ->
        {:error, validation_errors(errors)}
    end
  end

  defp is_module(module) do
    is_atom(module) && Code.ensure_loaded?(module)
  end

  defp validation_errors(errors) do
    errors
    |> Enum.map(&Tuple.delete_at(&1, 0))
    |> Enum.group_by(&elem(&1, 0), fn {_field, validation, message} ->
      {message, validation: validation}
    end)
  end

  defp validate_indexes(indexes) do
    invalid =
      indexes
      |> Enum.map(&validate_index/1)
      |> Enum.reject(&match?({:ok, _}, &1))
      |> Enum.map(&elem(&1, 1))

    if length(invalid) == 0 do
      :ok
    else
      {:error, List.flatten(invalid)}
    end
  end

  defp validate_index({_name, settings}) do
    Vex.validate(
      settings,
      settings: [presence: true, by: &is_binary/1],
      store: [presence: true, by: &is_module/1],
      sources: [
        presence: true,
        by: &(is_list(&1) && Enum.map(&1, fn source -> is_atom(source) end))
      ],
      bulk_page_size: [presence: true, by: &is_integer/1],
      bulk_wait_interval: [presence: true, by: &is_integer/1]
    )
  end
end
