defmodule Mixpanel do
  use Application

  alias Mixpanel.Client

  @typedoc """
  Possible options to be passed to `Mixpanel.track/3`.

  * `:distinct_id` - The value of distinct_id will be treated as a string, and
    used to uniquely identify a user associated with your event. If you provide
    a distinct_id with your events, you can track a given user through funnels
    and distinguish unique users for retention analyses. You should always send
    the same distinct_id when an event is triggered by the same user.

  * `:time` - The time an event occurred. If this property is not included in
    your request, Mixpanel will use the time the event arrives at the server.
    If present, the value should be one of:
    * `NaiveDateTime` struct (Etc/UTC timezone is assumed)
    * `DateTime` struct
    * a Unix timestamp (seconds since midnight, January 1st, 1970 - UTC)
    * an Erlang's `:erlang.timestamp()` tuple (`{mega_secs, secs, ms}`,
    microseconds are not supported)
    * an Erlang's `:calendar.datetime()` tuple (`{{yyyy, mm, dd}, {hh, mm, ss}}`)
  * `:ip` - An IP address string (e.g. "127.0.0.1") associated with the event.
  This is used for adding geolocation data to events, and should only be
  required if you are making requests from your backend. If `:ip` is absent,
  Mixpanel will ignore the IP address of the request.
  """
  @type track_options :: [
          time:
            DateTime.t()
            | NaiveDateTime.t()
            | :erlang.timestamp()
            | :calendar.datetime()
            | pos_integer(),
          distinct_id: String.t(),
          ip: String.t()
        ]

  @moduledoc """
  Elixir client for the Mixpanel API.
  """

  @spec start(any, any) :: :ignore | {:error, any} | {:ok, pid}
  def start(_type, _args) do
    Mixpanel.Supervisor.start_link()
  end

  @doc """
  Tracks an event.

  ## Arguments

    * `event` - A name for the event
    * `properties` - A collection of properties associated with this event.
    * `opts` - See `t:track_options/0` for specific options to pass to this
      function.

  """
  @spec track(Client.event(), Client.properties(), track_options) :: :ok
  def track(event, properties \\ %{}, opts \\ []) do
    validate_options(opts, [:distinct_id, :ip, :time], :opts)

    properties =
      properties
      |> Map.drop([:distinct_id, :ip, :time])
      |> maybe_put(:time, to_timestamp(Keyword.get(opts, :time)))
      |> maybe_put(:distinct_id, Keyword.get(opts, :distinct_id))
      |> maybe_put(:ip, convert_ip(Keyword.get(opts, :ip)))

    Client.track(event, properties)
  end

  @doc """
  Stores a user profile

  ## Arguments

  * `distinct_id` - This is a string that identifies the profile you would like to update.
  * `operation`   - A name for the event
  * `value`       - A collection of properties associated with this event.
  * `opts`        - The options

  ## Options

  * `:ip` - The IP address associated with a given profile. If `:ip` isn't
    provided, Mixpanel will use the IP address of the request. Mixpanel uses an
    IP address to guess at the geographic location of users. If `:ip` is set to
    "0", Mixpanel will ignore IP information.
  * `:time` - Seconds since midnight, January 1st 1970, UTC. Updates are applied
    in `:time` order, so setting this value can lead to unexpected results
    unless care is taken. If `:time` is not included in a request, Mixpanel will
    use the time the update arrives at the Mixpanel server.
  * `:ignore_time` - If the `:ignore_time` property is present and `true` in
    your update request, Mixpanel will not automatically update the "Last Seen"
    property of the profile. Otherwise, Mixpanel will add a "Last Seen" property
    associated with the current time for all $set, $append, and $add operations.
  """
  @spec engage(Client.distinct_id(), String.t(), map, keyword) :: :ok
  def engage(distinct_id, operation, value \\ %{}, opts \\ []) do
    validate_options(opts, [:ip, :time, :ignore_time], :opts)

    distinct_id
    |> build_engage_event(operation, value, opts)
    |> Client.engage()
  end

  @spec batch_engage([{Client.distinct_id(), String.t(), map}], keyword) :: :ok
  def batch_engage(list, opts \\ []) do
    validate_options(opts, [:ip, :time, :ignore_time], :opts)

    events =
      for {distinct_id, operation, value} <- list do
        build_engage_event(distinct_id, operation, value, opts)
      end

    Client.engage(events)
  end

  defp build_engage_event(distinct_id, operation, value, opts) do
    %{"$distinct_id": distinct_id}
    |> Map.put(operation, value)
    |> maybe_put(:"$ip", convert_ip(Keyword.get(opts, :ip)))
    |> maybe_put(:"$time", to_timestamp(Keyword.get(opts, :time)))
    |> maybe_put(:"$ignore_time", Keyword.get(opts, :ignore_time, nil) == true)
  end

  @doc """
  Creates an alias for a distinct ID, merging two profiles. Mixpanel supports
  adding an alias to a distinct id. An alias is a new value that will be
  interpreted by Mixpanel as an existing value. That means that you can send
  messages to Mixpanel using the new value, and Mixpanel will continue to use
  the old value for calculating funnels and retention reports, or applying
  updates to user profiles.

  ## Arguments

  * `alias_id` - The new additional ID of the user.
  * `distinct_id` - The current ID of the user.

  """
  @spec create_alias(Client.alias_id(), Client.distinct_id()) :: :ok
  def create_alias(alias_id, distinct_id) do
    Client.create_alias(alias_id, distinct_id)
  end

  @spec maybe_put(Map.t(), any, any) :: Map.t()
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @spec to_timestamp(
          nil
          | DateTime.t()
          | NaiveDateTime.t()
          | :erlang.timestamp()
          | :calendar.datetime()
          | pos_integer()
        ) :: pos_integer
  defp to_timestamp(nil), do: nil

  defp to_timestamp(secs) when is_integer(secs),
    do: secs

  defp to_timestamp(%NaiveDateTime{} = dt),
    do: dt |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()

  defp to_timestamp(%DateTime{} = dt),
    do: DateTime.to_unix(dt)

  defp to_timestamp({{_y, _mon, _d}, {_h, _m, _s}} = dt),
    do:
      dt
      |> :calendar.datetime_to_gregorian_seconds()
      |> Kernel.-(unquote(:calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})))

  defp to_timestamp({mega_secs, secs, _ms}),
    do: mega_secs * 1_000_000 + secs

  @spec convert_ip({1..255, 1..255, 1..255, 1..255}) :: String.t()
  defp convert_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp convert_ip(ip), do: ip

  @spec validate_options(Keyword.t(), [atom(), ...], String.t() | atom()) ::
          Keyword.t() | no_return()
  defp validate_options(options, valid_values, name) do
    case Keyword.split(options, valid_values) do
      {options, []} ->
        options

      {_, illegal_options} ->
        raise "Unsupported keys(s) in #{name}: #{inspect(Keyword.keys(illegal_options))}"
    end
  end
end
