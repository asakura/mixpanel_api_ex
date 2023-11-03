defmodule Mixpanel.TelemetryCollector do
  @moduledoc false

  use GenServer

  @type event ::
          {:telemetry.event_name(), :telemetry.event_measurements(), :telemetry.event_metadata()}
  @type state :: [event]

  @spec start_link([[atom, ...]]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(event_names) do
    GenServer.start_link(__MODULE__, event_names)
  end

  @spec record_event(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata(),
          GenServer.server()
        ) :: :ok
  def record_event(event, measurements, metadata, pid) do
    GenServer.cast(pid, {:event, event, measurements, metadata})
  end

  @spec get_events(GenServer.server()) :: state
  def get_events(pid) do
    GenServer.call(pid, :get_events)
  end

  @impl GenServer
  @spec init([[atom, ...]]) :: {:ok, []}
  def init(event_names) do
    :telemetry.attach_many(
      "#{inspect(self())}.trace",
      event_names,
      &__MODULE__.record_event/4,
      self()
    )

    {:ok, []}
  end

  @impl GenServer
  @spec handle_cast(
          {:event, :telemetry.event_name(), :telemetry.event_measurements(),
           :telemetry.event_metadata()},
          state
        ) :: {:noreply, state}
  def handle_cast({:event, event, measurements, metadata}, events) do
    {:noreply, [{event, measurements, metadata} | events]}
  end

  @impl GenServer
  @spec handle_call(:get_events, any, state) :: {:reply, state, state}
  def handle_call(:get_events, _from, events) do
    {:reply, Enum.reverse(events), events}
  end
end
