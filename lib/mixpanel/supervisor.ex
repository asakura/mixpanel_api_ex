defmodule Mixpanel.Supervisor do
  use Supervisor

  @moduledoc """


  """

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    token = Application.get_env(:mixpanel, :token)

    if token == nil do
      raise "Please set :mixpanel, :token in your app environment's config"
    end

    children = [
      worker(Mixpanel.Client, [token, [name: Mixpanel.Client]])
    ]

    supervise(children, strategy: :one_for_one, name: Mixpanel.Supervisor)
  end
end
