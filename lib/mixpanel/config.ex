defmodule Mixpanel.Config do
  @moduledoc false

  @type project_token :: String.t()
  @type base_url :: String.t()
  @type http_adapter :: module()
  @type name :: atom

  @type option ::
          {:project_token, project_token}
          | {:base_url, base_url}
          | {:http_adapter, http_adapter}
          | {:name, name}

  @type options :: [option, ...]

  @base_url "https://api.mixpanel.com"

  @spec clients() :: [name]
  def clients() do
    for {name, config} <- Application.get_all_env(:mixpanel_api_ex) do
      client(name, config)
    end
  end

  @spec client(module, keyword) :: {module, options} | nil
  defp client(name, opts) when is_atom(name) and is_list(opts) do
    config =
      opts
      |> Keyword.put_new(:name, name)
      |> Keyword.put_new(:base_url, @base_url)
      |> Keyword.put_new(:http_adapter, Mixpanel.HTTP.HTTPC)

    {name, config}
  end

  defp client(name, _) when not is_atom(name),
    do: raise(ArgumentError, "Expected a module name as a client name, got #{inspect(name)}")

  defp client(_, _), do: nil
end
