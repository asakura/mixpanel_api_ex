defmodule Mixpanel.Config do
  @moduledoc false

  @type project_token :: String.t()
  @type base_url :: String.t()
  @type http_adapter :: Mixpanel.HTTP.HTTPC | Mixpanel.HTTP.Hackney | Mixpanel.HTTP.NoOp
  @type name :: atom

  @type option ::
          {:project_token, project_token}
          | {:base_url, base_url}
          | {:http_adapter, http_adapter}
          | {:name, name}

  @type options :: [option, ...]

  @base_url "https://api.mixpanel.com"
  @known_adapters [Mixpanel.HTTP.HTTPC, Mixpanel.HTTP.Hackney, Mixpanel.HTTP.NoOp]

  @spec clients() :: [{name, options}]
  def clients() do
    for {name, config} <- Application.get_all_env(:mixpanel_api_ex) do
      {name, client(name, config)}
    end
  end

  @spec client(name, keyword) :: options | nil
  def client(name, opts) when is_atom(name) and is_list(opts) do
    config =
      opts
      |> Keyword.put_new(:name, name)
      |> Keyword.put_new(:base_url, @base_url)
      |> Keyword.put_new(:http_adapter, Mixpanel.HTTP.HTTPC)

    validate_http_adapter!(config[:http_adapter])

    config
  end

  def client(name, _) when not is_atom(name),
    do: raise(ArgumentError, "Expected a module name as a client name, got #{inspect(name)}")

  def client(_, _), do: nil

  defp validate_http_adapter!(adapter) when adapter in @known_adapters,
    do: :ok

  defp validate_http_adapter!(http_adapter),
    do: raise(ArgumentError, "Expected a valid http adapter, got #{inspect(http_adapter)}")
end
