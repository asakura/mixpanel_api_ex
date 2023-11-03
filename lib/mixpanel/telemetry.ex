defmodule Mixpanel.Telemetry do
  @moduledoc """
  The following telemetry spans are emitted by mixpanel_api_ex:

  ## `[:mixpanel_api_ex, :client, *]`

  Represents a Mixpanel API client is ready

  This span is started by the following event:

  * `[:mixpanel_api_ex, :client, :start]`

      Represents the start of the span

      This event contains the following measurements:

      * `monotonic_time`: The time of this event, in `:native` units

      This event contains the following metadata:

      * `name`: The name of the client
      * `base_url`: The URL which a client instance uses to communicate with
        the Mixpanel API
      * `http_adapter`: The HTTP adapter which a client instance uses to send
        actual requests to the backend

  This span is ended by the following event:

  * `[:mixpanel_api_ex, :client, :stop]`

      Represents the end of the span

      This event contains the following measurements:

      * `monotonic_time`: The time of this event, in `:native` units
      * `duration`: The span duration, in `:native` units

      This event contains the following metadata:

      * `name`: The name of the client
      * `base_url`: The URL which a client instance uses to communicate with
        the Mixpanel API
      * `http_adapter`: The HTTP adapter which a client instance uses to send
        actual requests to the backend

  The following events may be emitted within this span:

  * `[:mixpanel_api_ex, :client, :send]`

      Represents a request sent to the Mixpanel API

      This event contains the following measurements:

      * `event`: The name of the event that was sent
      * `payload_size`: The size (in bytes) of the payload has been sent

      This event contains the following metadata:

      * `telemetry_span_context`: A unique identifier for this span
      * `name`: The name of the client

  * `[:mixpanel_api_ex, :client, :send_error]`

      An error occurred while sending a request to the Mixpanel API

      This event contains the following measurements:

      * `event`: The name of the event that was attempted to send
      * `error`: A description of the error
      * `payload_size`: The size (in bytes) of the payload that were attempted to send

      This event contains the following metadata:

      * `telemetry_span_context`: A unique identifier for this span
      * `name`: The name of the client
  """

  @enforce_keys [:span_name, :telemetry_span_context, :start_time, :start_metadata]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          span_name: span_name,
          telemetry_span_context: reference,
          start_time: integer,
          start_metadata: metadata
        }

  @type span_name :: :client
  @type metadata :: :telemetry.event_metadata()

  @typedoc false
  @type measurements :: :telemetry.event_measurements()

  @typedoc false
  @type event_name :: :ready | :send_error

  @typedoc false
  @type untimed_event_name :: :stop | :send

  @app_name :mixpanel_api_ex

  @doc false
  @spec start_span(span_name, measurements, metadata) :: t
  def start_span(span_name, measurements, metadata) do
    measurements = Map.put_new_lazy(measurements, :monotonic_time, &monotonic_time/0)
    telemetry_span_context = make_ref()
    metadata = Map.put(metadata, :telemetry_span_context, telemetry_span_context)
    _ = event([span_name, :start], measurements, metadata)

    %__MODULE__{
      span_name: span_name,
      telemetry_span_context: telemetry_span_context,
      start_time: measurements[:monotonic_time],
      start_metadata: metadata
    }
  end

  @doc false
  @spec stop_span(t, measurements, metadata) :: :ok
  def stop_span(span, measurements \\ %{}, metadata \\ %{}) do
    measurements = Map.put_new_lazy(measurements, :monotonic_time, &monotonic_time/0)

    measurements =
      Map.put(measurements, :duration, measurements[:monotonic_time] - span.start_time)

    metadata = Map.merge(span.start_metadata, metadata)

    untimed_span_event(span, :stop, measurements, metadata)
  end

  @doc false
  @spec span_event(t, event_name, measurements, metadata) :: :ok
  def span_event(span, name, measurements \\ %{}, metadata \\ %{}) do
    measurements = Map.put_new_lazy(measurements, :monotonic_time, &monotonic_time/0)
    untimed_span_event(span, name, measurements, metadata)
  end

  @doc false
  @spec untimed_span_event(t, event_name | untimed_event_name, measurements, metadata) ::
          :ok
  def untimed_span_event(span, name, measurements \\ %{}, metadata \\ %{}) do
    metadata = Map.put(metadata, :telemetry_span_context, span.telemetry_span_context)
    event([span.span_name, name], measurements, metadata)
  end

  @spec monotonic_time() :: integer
  defdelegate monotonic_time, to: System

  defp event(suffix, measurements, metadata) do
    :telemetry.execute([@app_name | suffix], measurements, metadata)
  end
end
