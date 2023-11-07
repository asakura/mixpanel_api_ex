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
    Application.get_env(:mixpanel_api_ex, :clients, [])
  end

  @spec client(name) :: options
  def client(name) do
    Application.get_env(:mixpanel_api_ex, name, [])
    |> Keyword.put_new(:name, name)
    |> Keyword.put_new(:base_url, @base_url)
    |> Keyword.put_new(:http_adapter, HTTP.HTTPC)
  end
end
