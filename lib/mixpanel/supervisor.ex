defmodule Mixpanel.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  @spec start_link() :: Supervisor.on_start()
  def start_link(), do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  @spec start_link(any) :: Supervisor.on_start()
  def start_link(_), do: start_link()

  @spec start_child(Mixpanel.Config.options()) :: DynamicSupervisor.on_start_child()
  def start_child(config),
    do: DynamicSupervisor.start_child(__MODULE__, {Mixpanel.Client, config})

  @doc export: true
  @spec terminate_child(Mixpanel.Config.name()) :: :ok | {:error, :not_found}
  def terminate_child(client) do
    case Process.whereis(client) do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      _ ->
        {:error, :not_found}
    end
  end

  @spec init(any) :: {:ok, DynamicSupervisor.sup_flags()}
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
