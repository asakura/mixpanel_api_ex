defmodule Mixpanel.Supervisor do
  use Supervisor

  @moduledoc """
  A simple supervisor which manages API Client process alive.
  """

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(clients) do
    Supervisor.start_link(__MODULE__, clients, name: __MODULE__)
  end

  @spec init(keyword) ::
          {:ok,
           {Supervisor.sup_flags(),
            [Supervisor.child_spec() | (old_erlang_child_spec :: :supervisor.child_spec())]}}
  def init(clients) do
    children =
      for client <- clients do
        if not is_atom(client) do
          raise ArgumentError, "Expected :atom as a client name, got #{inspect(client)}"
        end

        config =
          Application.get_env(:mixpanel_api_ex, client, [])
          |> Keyword.put(:name, client)

        Supervisor.child_spec({Mixpanel.Client, config}, id: client)
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
