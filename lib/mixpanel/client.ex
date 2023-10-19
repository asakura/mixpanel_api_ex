defmodule Mixpanel.Client do
  use GenServer

  @moduledoc """


  """

  require Logger

  @base_url "https://api.mixpanel.com"
  @track_endpoint "/track"
  @engage_endpoint "/engage"
  @alias_endpoint "/track#identity-create-alias"

  def start_link(init_args) do
    {opts, gen_server_opts} = Keyword.split(init_args, [:token, :active, :base_url])

    GenServer.start_link(__MODULE__, opts, gen_server_opts)
  end

  def child_spec(init_args) do
    init_args =
      case Keyword.has_key?(init_args, :name) do
        true ->
          init_args

        false ->
          [{:name, __MODULE__} | init_args]
      end

    init_args =
      case Keyword.has_key?(init_args, :base_url) do
        true ->
          init_args

        false ->
          [{:base_url, @base_url} | init_args]
      end

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_args]}
    }
  end

  @doc """
  Tracks a event

  See `Mixpanel.track/3`
  """
  @spec track(String.t(), Map.t()) :: :ok
  def track(event, properties \\ %{}) do
    GenServer.cast(__MODULE__, {:track, event, properties})
  end

  @doc """
  Updates a user profile.

  See `Mixpanel.engage/4`.
  """
  @spec engage(Map.t() | [Map.t()]) :: :ok
  def engage(event) do
    GenServer.cast(__MODULE__, {:engage, event})
  end

  @doc """
  Creates an alias for a user profile.

  See `Mixpanel.create_alias/2`.
  """
  @spec create_alias(String.t(), String.t()) :: :ok
  def create_alias(alias, distinct_id) do
    GenServer.cast(__MODULE__, {:create_alias, alias, distinct_id})
  end

  def init(config) do
    {:ok, Enum.into(config, %{})}
  end

  def handle_cast({:track, event, properties}, %{token: token, active: true} = state) do
    data =
      %{event: event, properties: Map.put(properties, :token, token)}
      |> Jason.encode!()
      |> :base64.encode()

    case HTTPoison.get(state.base_url <> @track_endpoint, [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        Logger.warning(
          "Problem tracking Mixpanel event: #{inspect(event)}, #{inspect(properties)} Got: #{inspect(other)}"
        )
    end

    {:noreply, state}
  end

  def handle_cast({:engage, event}, %{token: token, active: true} = state) do
    data =
      event
      |> put_token(token)
      |> Jason.encode!()
      |> :base64.encode()

    case HTTPoison.get(state.base_url <> @engage_endpoint, [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        Logger.warning(
          "Problem tracking Mixpanel profile update: #{inspect(event)} Got: #{inspect(other)}"
        )
    end

    {:noreply, state}
  end

  def handle_cast({:create_alias, alias, distinct_id}, %{token: token, active: true} = state) do
    data =
      %{
        event: "$create_alias",
        properties: %{
          token: token,
          alias: alias,
          distinct_id: distinct_id
        }
      }
      |> Jason.encode!()
      |> :base64.encode()

    case HTTPoison.post(state.base_url <> @alias_endpoint, "data=#{data}", [
           {"Content-Type", "application/x-www-form-urlencoded"}
         ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        Logger.warning(
          "Problem creating Mixpanel alias: alias=#{inspect(alias)}, distinct_id=#{inspect(distinct_id)} Got: #{inspect(other)}"
        )
    end

    {:noreply, state}
  end

  # No events submitted when env configuration is set to false.
  def handle_cast(_request, %{active: false} = state) do
    {:noreply, state}
  end

  defp put_token(events, token) when is_list(events), do: Enum.map(events, &put_token(&1, token))
  defp put_token(event, token), do: Map.put(event, :"$token", token)
end
