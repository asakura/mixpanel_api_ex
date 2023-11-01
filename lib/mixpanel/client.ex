defmodule Mixpanel.Client do
  use GenServer

  @moduledoc """
  Mixpanel API Client GenServer.
  """

  require Logger
  alias Mixpanel.HTTP

  @type project_token :: String.t()
  @type active :: boolean
  @type base_url :: String.t()
  @type option :: {:project_token, project_token} | {:active, active} | {:base_url, base_url}
  @type init_args :: [option | GenServer.option() | {Keyword.key(), Keyword.value()}, ...]
  @type state :: %{
          required(:project_token) => project_token,
          required(:active) => active,
          required(:base_url) => base_url
        }

  @type event :: String.t() | map
  @type properties :: map
  @type alias_id :: String.t()
  @type distinct_id :: String.t()

  @base_url "https://api.mixpanel.com"
  @track_endpoint "/track"
  @engage_endpoint "/engage"
  @alias_endpoint "/track#identity-create-alias"

  @spec start_link(init_args) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    {opts, gen_server_opts} = split_options(init_args)
    GenServer.start_link(__MODULE__, opts, gen_server_opts)
  end

  @spec init(init_args) :: {[option, ...], [GenServer.option(), ...]}
  defp split_options(init_args) do
    {opts, gen_server_opts} = Keyword.split(init_args, [:project_token, :active, :base_url])

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
    |> Keyword.put_new(:active, true)
  end

  @doc """
  Tracks a event

  See `Mixpanel.track/3`
  """
  @spec track(event, properties) :: :ok
  def track(event, properties) do
    GenServer.cast(__MODULE__, {:track, event, properties})
  end

  @doc """
  Updates a user profile.

  See `Mixpanel.engage/4`.
  """
  @spec engage(event | [event]) :: :ok
  def engage(event) do
    GenServer.cast(__MODULE__, {:engage, event})
  end

  @doc """
  Creates an alias for a user profile.

  See `Mixpanel.create_alias/2`.
  """
  @spec create_alias(alias_id, distinct_id) :: :ok
  def create_alias(alias, distinct_id) do
    GenServer.cast(__MODULE__, {:create_alias, alias, distinct_id})
  end

  @impl GenServer
  @spec init([option, ...]) :: {:ok, state}
  def init(opts) do
    project_token = Keyword.fetch!(opts, :project_token)
    active = Keyword.fetch!(opts, :active)
    base_url = Keyword.fetch!(opts, :base_url)

    {:ok,
     %{
       project_token: project_token,
       active: active,
       base_url: base_url
     }}
  end

  @spec handle_cast(
          {:track, event, properties}
          | {:engage, event}
          | {:create_alias, alias_id, distinct_id},
          state
        ) :: {:noreply, state}

  @impl GenServer
  def handle_cast(
        {:track, event, properties},
        %{project_token: project_token, active: true} = state
      ) do
    data =
      %{event: event, properties: Map.put(properties, :token, project_token)}
      |> Jason.encode!()
      |> :base64.encode()

    case HTTP.get(state.base_url <> @track_endpoint, [], params: [data: data]) do
      {:ok, _, _, _} ->
        :ok

      _ ->
        Logger.warning(%{message: "Problem tracking event", event: event, properties: properties})
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:engage, event}, %{project_token: project_token, active: true} = state) do
    data =
      event
      |> put_token(project_token)
      |> Jason.encode!()
      |> :base64.encode()

    case HTTP.get(state.base_url <> @engage_endpoint, [], params: [data: data]) do
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
        %{project_token: project_token, active: true} = state
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
      |> Jason.encode!()
      |> :base64.encode()

    case HTTP.post(
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

  # No events submitted when env configuration is set to false.
  def handle_cast(_request, %{active: false} = state) do
    {:noreply, state}
  end

  defp put_token(events, project_token) when is_list(events),
    do: Enum.map(events, &put_token(&1, project_token))

  defp put_token(event, project_token),
    do: Map.put(event, :"$token", project_token)
end
