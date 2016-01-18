defmodule Mixpanel do
  use Application

  @moduledoc """
  Elixir client for the Mixpanel API.
  """

  def start(_type, _args) do
    Mixpanel.Supervisor.start_link
  end

  @doc """
  Tracks an event.

  ## Arguments

    * `event`      - A name for the event
    * `properties` - A collection of properties associated with this event.
    * `opts`       - The options

  ## Options

    * `:distinct_id` - The value of distinct_id will be treated as a string, and used to uniquely identify a user associated with your event. If you provide a distinct_id property with your events, you can track a given user through funnels and distinguish unique users for retention analyses. You should always send the same distinct_id when an event is triggered by the same user.
    * `:time`        - The time an event occurred. If present, the value should be a unix timestamp (seconds since midnight, January 1st, 1970 - UTC). If this property is not included in your request, Mixpanel will use the time the event arrives at the server.
    * `:ip`          - An IP address string (e.g. "127.0.0.1") associated with the event. This is used for adding geolocation data to events, and should only be required if you are making requests from your backend. If `:ip` is absent, Mixpanel will ignore the IP address of the request.

  """
  @spec track(String.t, Map.t, Keyword.t) :: :ok
  def track(event, properties \\ %{}, opts \\ []) do
    properties = properties
    |> track_put_time(Keyword.get(opts, :time))
    |> track_put_distinct_id(Keyword.get(opts, :distinct_id))
    |> track_put_ip(Keyword.get(opts, :ip))

    Mixpanel.Client.track(event, properties)

    :ok
  end

  defp track_put_time(properties, nil), do: properties
  defp track_put_time(properties, {mega_secs, secs, _ms}), do: track_put_time(properties, mega_secs * 10_000 + secs)
  defp track_put_time(properties, secs) when is_integer(secs), do: Map.put(properties, :time, secs)

  defp track_put_distinct_id(properties, nil), do: properties
  defp track_put_distinct_id(properties, distinct_id), do: Map.put(properties, :distinct_id, distinct_id)

  defp track_put_ip(properties, nil), do: properties
  defp track_put_ip(properties, ip), do: Map.put(properties, :ip, ip)

  @doc """
  Stores a user profile

  ## Arguments

    * `distinct_id` - This is a string that identifies the profile you would like to update.
    * `operation`   - A name for the event
    * `value`       - A collection of properties associated with this event.
    * `opts`        - The options

  ## Options

    * `:ip`          - The IP address associated with a given profile. If `:ip` isn't provided, Mixpanel will use the IP address of the request. Mixpanel uses an IP address to guess at the geographic location of users. If `:ip` is set to "0", Mixpanel will ignore IP information.
    * `:time`        - Seconds since midnight, January 1st 1970, UTC. Updates are applied in `:time` order, so setting this value can lead to unexpected results unless care is taken. If `:time` is not included in a request, Mixpanel will use the time the update arrives at the Mixpanel server.
    * `:ignore_time` - If the `:ignore_time` property is present and `true` in your update request, Mixpanel will not automatically update the "Last Seen" property of the profile. Otherwise, Mixpanel will add a "Last Seen" property associated with the current time for all $set, $append, and $add operations.
    """
  @spec engage(String.t, String.t, Map.t, Keyword.t) :: :ok
  def engage(distinct_id, operation, value \\ %{}, opts \\ []) do
    event = %{"$distinct_id": distinct_id}
    |> Map.put(operation, value)
    |> engage_put_ip(Keyword.get(opts, :ip))
    |> engage_put_time(Keyword.get(opts, :time))
    |> engage_put_ignore_time(Keyword.get(opts, :ignore_time))

    Mixpanel.Client.engage(event)

    :ok
  end

  defp engage_put_ip(event, nil), do: event
  defp engage_put_ip(event, ip), do: Map.put(event, :"$ip", ip)

  defp engage_put_time(event, nil), do: event
  defp engage_put_time(event, {mega_secs, secs, _ms}), do: engage_put_time(event, mega_secs * 10_000 + secs)
  defp engage_put_time(event, secs) when is_integer(secs), do: Map.put(event, :"$time", secs)

  defp engage_put_ignore_time(event, true), do: Map.put(event, :"$ignore_time", "true")
  defp engage_put_ignore_time(event, _), do: event
end
