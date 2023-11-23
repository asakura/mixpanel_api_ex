defmodule Mixpanel do
  @moduledoc """
  Elixir client for the Mixpanel API.
  """

  use Application

  alias Mixpanel.Client

  require Logger

  @doc false
  @doc export: true
  @spec __using__(any) :: Macro.t()
  defmacro __using__(_) do
    quote do
      @behaviour Mixpanel

      @spec track(Client.event(), Client.properties(), Mixpanel.track_options()) :: :ok
      def track(event, properties \\ %{}, opts \\ []),
        do: Client.track(unquote(__CALLER__.module), event, properties, opts)

      @spec engage([{Client.distinct_id(), String.t(), map}], Mixpanel.engage_options()) :: :ok
      def engage(batch, opts \\ []),
        do: Client.engage(unquote(__CALLER__.module), batch, opts)

      @spec engage(Client.distinct_id(), String.t(), map, Mixpanel.engage_options()) :: :ok
      def engage(distinct_id, operation, value, opts \\ []),
        do: Client.engage(unquote(__CALLER__.module), distinct_id, operation, value, opts)

      @spec create_alias(Client.alias_id(), Client.distinct_id()) :: :ok
      def create_alias(alias_id, distinct_id),
        do: Client.create_alias(unquote(__CALLER__.module), alias_id, distinct_id)
    end
  end

  @typedoc """
  Possible common options to be passed to `Mixpanel.track/3` and `Mixpanel.engage/3`.

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
  @type common_options :: [
          time:
            DateTime.t()
            | NaiveDateTime.t()
            | :erlang.timestamp()
            | :calendar.datetime()
            | pos_integer(),
          ip: {1..255, 0..255, 0..255, 0..255} | String.t()
        ]

  @typedoc """
  Possible options to be passed to `Mixpanel.track/3`.

  * `:distinct_id` - The value of distinct_id will be treated as a string, and
    used to uniquely identify a user associated with your event. If you provide
    a distinct_id with your events, you can track a given user through funnels
    and distinguish unique users for retention analyses. You should always send
    the same distinct_id when an event is triggered by the same user.
  """
  @type track_options ::
          common_options
          | [
              distinct_id: String.t()
            ]

  @typedoc """
  Possible options to be passed to `Mixpanel.engage/3`.

  * `:ignore_time` - If the `:ignore_time` property is present and `true` in
    your update request, Mixpanel will not automatically update the "Last Seen"
    property of the profile. Otherwise, Mixpanel will add a "Last Seen" property
    associated with the current time for all $set, $append, and $add operations.
  """
  @type engage_options ::
          common_options
          | [
              ignore_time: boolean
            ]

  @impl Application
  @spec start(any, any) :: Supervisor.on_start()
  def start(_type, _args) do
    Mixpanel.Supervisor.start_link()
  end

  @impl Application
  @spec start_phase(:clients, :normal, any) :: :ok
  def start_phase(:clients, :normal, _phase_args) do
    for {client, config} <- Mixpanel.Config.clients!() do
      case Mixpanel.Supervisor.start_child(config) do
        {:ok, _pid} ->
          :ok

        {:ok, _pid, _info} ->
          :ok

        :ignore ->
          Logger.warning("#{client} was not started")

        {:error, reason} ->
          Logger.error("Could not start #{client} because of #{inspect(reason)}")
      end
    end

    :ok
  end

  @impl Application
  def prep_stop(state), do: state

  @impl Application
  def stop(_state), do: :ok

  @doc """
  Dynamically starts a new client process.

  ## Examples

      iex> Mixpanel.start_client(Mixpanel.Config.client!(MyApp.Mixpanel.US, [project_token: "token"]))
      {:ok, #PID<0.123.0>}
      iex> Mixpanel.start_client(Mixpanel.Config.client!(MyApp.Mixpanel.US, [project_token: "token"]))
      {:error, {:already_started, #PID<0.298.0>}}
  """
  @doc export: true
  @spec start_client(Mixpanel.Config.options()) :: DynamicSupervisor.on_start_child()
  defdelegate start_client(config), to: Mixpanel.Supervisor, as: :start_child

  @doc """
  Stops a client process.

  ## Examples

      iex> Mixpanel.terminate_client(MyApp.Mixpanel.US)
      :ok
      iex> Mixpanel.terminate_client(MyApp.Mixpanel.US)
      {:error, :not_found}
      iex> Process.whereis(MyApp.Mixpanel.EU)
      nil
  """
  @doc export: true
  @spec terminate_client(Mixpanel.Config.name()) :: :ok | {:error, :not_found}
  defdelegate terminate_client(client), to: Mixpanel.Supervisor, as: :terminate_child

  @doc """
  Tracks an event.

  ## Arguments

  * `event` - A name for the event.
  * `properties` - A collection of properties associated with this event.
  * `opts` - See `t:track_options/0` for specific options to pass to this
    function.
  """
  @callback track(Client.event(), Client.properties(), track_options) :: :ok

  @doc """
  Same as `f:engage/4`, but accepts a list of `{distinct_id, operation, value}`
  tuples, then forms a batch request and send it the Ingestion API.

  ## Arguments

  * `batch` - See `f:engage/4` for details.
  * `opts` - See `t:engage_options/0` for specific options to pass to this
    function.
  """
  @callback engage([{Client.distinct_id(), String.t(), map}], engage_options) :: :ok

  @doc """
  Takes a `value` map argument containing names and values of profile
  properties. If the profile does not exist, it creates it with these
  properties. If it does exist, it sets the properties to these values,
  overwriting existing values.

  ## Arguments

  * `distinct_id` - This is a string that identifies the profile you would like
    to update.
  * `operation` - A name for the event.
  * `value`- A collection of properties associated with this event.
  * `opts` - See `t:engage_options/0` for specific options to pass to this
    function.
  """
  @callback engage(Client.distinct_id(), String.t(), map, engage_options) :: :ok

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
  @callback create_alias(Client.alias_id(), Client.distinct_id()) :: :ok
end
