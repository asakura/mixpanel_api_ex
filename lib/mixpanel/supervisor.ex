defmodule Mixpanel.Supervisor do
  use Supervisor

  @moduledoc """
  A simple supervisor which manages API Client process alive.
  """

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link() do
    config = Application.get_env(:mixpanel_api_ex, :config)

    if config[:project_token] == nil do
      raise ArgumentError, "Please set :mixpanel_api_ex, :token in your app environment's config"
    end

    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @spec init(keyword) ::
          {:ok,
           {Supervisor.sup_flags(),
            [Supervisor.child_spec() | (old_erlang_child_spec :: :supervisor.child_spec())]}}
  def init(config) do
    children = [
      {Mixpanel.Client, config}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
