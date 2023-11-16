defmodule Mixpanel.Supervisor do
  use DynamicSupervisor

  @moduledoc """
  A simple supervisor which manages API Client process alive.
  """

  @spec start_link() :: Supervisor.on_start()
  def start_link(), do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  @spec start_link(any) :: Supervisor.on_start()
  def start_link(_), do: start_link()

  @spec start_child(Mixpanel.Config.options()) ::
          {:error, any} | {:ok, pid}
  def start_child(config) do
    DynamicSupervisor.start_child(__MODULE__, {Mixpanel.Client, config})
  end

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
