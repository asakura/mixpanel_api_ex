defmodule Mixpanel.Client do
  use GenServer

  @moduledoc """
  Mixpanel API Client GenServer.
  """

  require Logger

  alias Mixpanel.Client.State
  alias Mixpanel.HTTP

  @type option ::
          {:project_token, State.project_token()}
          | {:base_url, State.base_url()}
          | {:http_adapter, module}
  @type init_args :: [option | GenServer.option() | {Keyword.key(), Keyword.value()}, ...]

  @type event :: String.t() | map
  @type properties :: map
  @type alias_id :: String.t()
  @type distinct_id :: String.t()

  @base_url "https://api.mixpanel.com"
  @track_endpoint "/track"
  @engage_endpoint "/engage"
  @alias_endpoint "/track#identity-create-alias"
  @epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

  @spec start_link(init_args) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    {opts, gen_server_opts} = split_options(init_args)
    GenServer.start_link(__MODULE__, opts, gen_server_opts)
  end

  @spec init(init_args) :: {[option, ...], [GenServer.option(), ...]}
  defp split_options(init_args) do
    {opts, gen_server_opts} =
      Keyword.split(init_args, [:project_token, :base_url, :http_adapter])

    gen_server_opts =
      Keyword.take(gen_server_opts, [:debug, :name, :timeout, :spawn_opt, :hibernate_after])

    {opts, gen_server_opts}
  end

  @spec child_spec(init_args) :: %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [init_args, ...]}
        }
  def child_spec(init_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [put_default_opts(init_args)]}
    }
  end

  @spec put_default_opts(init_args) :: init_args
  defp put_default_opts(init_args) do
    init_args
    |> Keyword.put_new(:name, __MODULE__)
    |> Keyword.put_new(:base_url, @base_url)
    |> Keyword.put_new(:http_adapter, HTTP.HTTPC)
  end

  @doc """
  Tracks a event

  See `Mixpanel.track/3`
  """
  @spec track(module, event, properties, Mixpanel.track_options()) :: :ok
  def track(server, event, properties, opts) do
    opts = validate_options(opts, [:distinct_id, :ip, :time], :opts)

    properties =
      properties
      |> Map.drop([:distinct_id, :ip, :time])
      |> maybe_put(:time, to_timestamp(Keyword.get(opts, :time)))
      |> maybe_put(:distinct_id, Keyword.get(opts, :distinct_id))
      |> maybe_put(:ip, convert_ip(Keyword.get(opts, :ip)))

    GenServer.cast(server, {:track, event, properties})
  end

  @doc """
  Updates a user profile.

  See `Mixpanel.engage/4`.
  """
  @spec engage(module, [{distinct_id, String.t(), map}], Mixpanel.engage_options()) ::
          :ok
  def engage(server, [{_, _, _} | _] = batch, opts) do
    opts = validate_options(opts, [:ip, :time, :ignore_time], :opts)
    GenServer.cast(server, {:engage, Enum.map(batch, &build_engage_event(&1, opts))})
  end

  @spec engage(module, distinct_id, String.t(), map, Mixpanel.engage_options()) :: :ok
  def engage(server, distinct_id, operation, value, opts) do
    opts = validate_options(opts, [:ip, :time, :ignore_time], :opts)
    GenServer.cast(server, {:engage, build_engage_event({distinct_id, operation, value}, opts)})
  end

  @doc """
  Creates an alias for a user profile.

  See `Mixpanel.create_alias/2`.
  """
  @spec create_alias(module, alias_id, distinct_id) :: :ok
  def create_alias(server, alias_id, distinct_id) do
    GenServer.cast(server, {:create_alias, alias_id, distinct_id})
  end

  @impl GenServer
  @spec init([option, ...]) :: {:ok, State.t()}
  def init(opts) do
    Process.flag(:trap_exit, true)
    state = State.new(opts)

    client_span =
      Mixpanel.Telemetry.start_span(:client, %{}, %{
        base_url: State.base_url(state),
        http_adapter: State.http_adapter(state)
      })

    {:ok, State.attach_span(state, client_span)}
  end

  @spec handle_cast(
          {:track, event, properties}
          | {:engage, event}
          | {:create_alias, alias_id, distinct_id},
          State.t()
        ) :: {:noreply, State.t()}

  @impl GenServer
  def handle_cast(
        {:track, event, properties},
        %State{project_token: project_token, http_adapter: http_adapter} = state
      ) do
    data = encode_params(%{event: event, properties: Map.put(properties, :token, project_token)})

    case HTTP.get(http_adapter, state.base_url <> @track_endpoint, [], params: [data: data]) do
      {:ok, _, _, _} ->
        :ok

      _ ->
        Logger.warning(%{message: "Problem tracking event", event: event, properties: properties})
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        {:engage, event},
        %State{project_token: project_token, http_adapter: http_adapter} = state
      ) do
    data =
      event
      |> put_token(project_token)
      |> encode_params()

    case HTTP.get(http_adapter, state.base_url <> @engage_endpoint, [], params: [data: data]) do
      {:ok, _, _, _} ->
        :ok

      _ ->
        Logger.warning(%{message: "Problem tracking profile update", event: event})
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        {:create_alias, alias, distinct_id},
        %State{project_token: project_token, http_adapter: http_adapter} = state
      ) do
    data =
      %{
        event: "$create_alias",
        properties: %{
          token: project_token,
          alias: alias,
          distinct_id: distinct_id
        }
      }
      |> encode_params()

    case HTTP.post(
           http_adapter,
           state.base_url <> @alias_endpoint,
           "data=#{data}",
           [
             {"Content-Type", "application/x-www-form-urlencoded"}
           ]
         ) do
      {:ok, _, _, _} ->
        :ok

      :ignore ->
        Logger.warning(%{
          message: "Problem creating profile alias",
          alias: alias,
          distinct_id: distinct_id
        })
    end

    {:noreply, state}
  end

  @impl GenServer
  @spec terminate(reason, State.t()) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term} | term
  def terminate(_reason, state),
    do: Mixpanel.Telemetry.stop_span(State.span(state))

  defp put_token(events, project_token) when is_list(events),
    do: Enum.map(events, &put_token(&1, project_token))

  defp put_token(event, project_token),
    do: Map.put(event, :"$token", project_token)

  defp encode_params(params),
    do: Jason.encode!(params) |> :base64.encode()

  defp build_engage_event({distinct_id, operation, value}, opts) do
    %{"$distinct_id": distinct_id}
    |> Map.put(operation, value)
    |> maybe_put(:"$ip", convert_ip(Keyword.get(opts, :ip)))
    |> maybe_put(:"$time", to_timestamp(Keyword.get(opts, :time)))
    |> maybe_put(:"$ignore_time", Keyword.get(opts, :ignore_time, nil) == true)
  end

  @spec to_timestamp(
          nil
          | DateTime.t()
          | NaiveDateTime.t()
          | :erlang.timestamp()
          | :calendar.datetime()
          | pos_integer
        ) :: nil | integer
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
      |> Kernel.-(@epoch)

  defp to_timestamp({mega_secs, secs, _ms}),
    do: trunc(mega_secs * 1_000_000 + secs)

  @spec convert_ip(nil | {1..255, 1..255, 1..255, 1..255} | String.t()) :: nil | String.t()
  defp convert_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp convert_ip(ip) when is_binary(ip), do: ip
  defp convert_ip(nil), do: nil

  @dialyzer {:nowarn_function, maybe_put: 3}

  @spec maybe_put(map, any, any) :: map
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @dialyzer {:nowarn_function, validate_options: 3}

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
