defmodule MixpanelTest.ClientTest do
  use ExUnit.Case, async: false
  use Machete

  describe "init/1" do
    test "emits expected telemetry event" do
      {:ok, collector_pid} =
        start_supervised({Mixpanel.TelemetryCollector, [[:mixpanel_api_ex, :client, :start]]})

      {:ok, %Mixpanel.Client.State{} = state} =
        Mixpanel.Client.init(
          project_token: "token",
          base_url: "base url",
          http_adapter: Mixpanel.HTTP.NoOp,
          name: make_ref()
        )

      # We expect a monotonic start time as a measurement in the event.
      assert Mixpanel.TelemetryCollector.get_events(collector_pid)
             ~> [
               {[:mixpanel_api_ex, :client, :start], %{monotonic_time: integer()},
                %{
                  telemetry_span_context: reference(),
                  name: state.name,
                  base_url: "base url",
                  http_adapter: Mixpanel.HTTP.NoOp
                }}
             ]
    end
  end

  describe "terminate/2" do
    test "emits telemetry event with expected timings" do
      {:ok, %Mixpanel.Client.State{} = state} =
        Mixpanel.Client.init(
          project_token: "token",
          base_url: "base url",
          http_adapter: Mixpanel.HTTP.NoOp,
          name: make_ref()
        )

      {:ok, collector_pid} =
        start_supervised({Mixpanel.TelemetryCollector, [[:mixpanel_api_ex, :client, :stop]]})

      Mixpanel.Client.terminate(:normal, state)

      # We expect a monotonic start time as a measurement in the event.
      assert [
               {[:mixpanel_api_ex, :client, :stop],
                %{monotonic_time: stop_monotonic_time, duration: duration}, stop_metadata}
             ] = Mixpanel.TelemetryCollector.get_events(collector_pid)

      assert is_integer(stop_monotonic_time)

      # We expect the duration to be the monotonic stop # time minus the monotonic start time.
      assert stop_monotonic_time >= state.span.start_time
      assert duration == stop_monotonic_time - state.span.start_time

      # The start and stop metadata should be equal.
      assert stop_metadata == state.span.start_metadata
    end
  end

  describe "handle_cast/2" do
    setup do
      {:ok, state} =
        Mixpanel.Client.init(
          project_token: "token",
          base_url: "base url",
          http_adapter: Mixpanel.HTTP.NoOp,
          name: make_ref()
        )

      {:ok, state: state}
    end

    test "emits telemetry event with expected timings", %{state: state} do
      {:ok, collector_pid} =
        start_supervised({Mixpanel.TelemetryCollector, [[:mixpanel_api_ex, :client, :send]]})

      {:noreply, %Mixpanel.Client.State{}} =
        Mixpanel.Client.handle_cast({:track, "event", %{}}, state)

      assert Mixpanel.TelemetryCollector.get_events(collector_pid)
             ~> [
               {[:mixpanel_api_ex, :client, :send], %{event: "event"},
                %{
                  telemetry_span_context: reference(),
                  name: state.name
                }}
             ]
    end
  end
end
