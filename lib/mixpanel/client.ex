defmodule Mixpanel.Client do
  use GenServer

  @moduledoc """


  """

  require Logger

  @track_endpoint "https://api.mixpanel.com/track"
  @engage_endpoint "https://api.mixpanel.com/engage"
  @alias_endpoint "https://api.mixpanel.com/track#identity-create-alias"

  def start_link(config, opts \\ []) do
    GenServer.start_link(__MODULE__, {:ok, config}, opts)
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
  @spec engage(Map.t()) :: :ok
  def engage(event) do
    GenServer.cast(__MODULE__, {:engage, event})
  end

  @doc """
  Creates an alias for a Mixpanel user.

  See `Mixpanel.create_alias/2`.
  """
  @spec create_alias(String.t(), String.t()) :: :ok
  def create_alias(alias, distinct_id) do
    GenServer.cast(__MODULE__, {:create_alias, alias, distinct_id})
  end

  def init({:ok, config}) do
    {:ok, Enum.into(config, %{})}
  end

  def handle_cast({:track, event, properties}, %{token: token, active: true} = state) do
    data =
      %{event: event, properties: Map.put(properties, :token, token)}
      |> Poison.encode!()
      |> :base64.encode()

    case HTTPoison.get(@track_endpoint, [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        Logger.warn(
          "Problem tracking Mixpanel event: #{inspect(event)}, #{inspect(properties)} Got: #{
            inspect(other)
          }"
        )
    end

    {:noreply, state}
  end

  def handle_cast({:engage, event}, %{token: token, active: true} = state) do
    data =
      event
      |> Map.put(:"$token", token)
      |> Poison.encode!()
      |> :base64.encode()

    case HTTPoison.get(@engage_endpoint, [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        Logger.warn(
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
      |> Poison.encode!()
      |> :base64.encode()

    case HTTPoison.post(@alias_endpoint, "data=#{data}", [{"Content-Type", "application/x-www-form-urlencoded"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        Logger.warn(
          "Problem creating Mixpanel alias: alias=#{inspect(alias)}, distinct_id=#{inspect(distinct_id)} Got: #{
            inspect(other)
          }"
        )
    end

    {:noreply, state}
  end


  # No events submitted when env configuration is set to false.
  def handle_cast(_request, %{active: false} = state) do
    {:noreply, state}
  end
end
