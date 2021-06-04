defmodule Mixpanel.Supervisor do
  use Supervisor

  @moduledoc false

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    config = Application.get_all_env(:mixpanel_api_ex)

    if config[:token] == nil do
      raise "Please set :mixpanel, :token in your app environment's config"
    end

    config = Keyword.put_new(config, :base_url, "https://api.mixpanel.com")

    children = [
      {Mixpanel.Client, [config, [name: Mixpanel.Client]]}
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Mixpanel.Supervisor)
  end
end
