defmodule Mixpanel.Client do
  use GenServer

  @moduledoc """


  """

  require Logger

  @track_endpoint "https://api.mixpanel.com/track"
  @engage_endpoint "https://api.mixpanel.com/engage"

  def start_link(token, opts \\ []) do
    GenServer.start_link(__MODULE__, {:ok, token}, opts)
  end

  @doc """
  Tracks a event

  See `Mixpanel.track/3`
  """
  @spec track(String.t, Map.t) :: :ok
  def track(event, properties \\ %{}) do
    GenServer.cast(__MODULE__, {:track, event, properties})
  end

  @doc """
  Updates a user profile.

  See `Mixpanel.engage/4`.
  """
  @spec engage(Map.t) :: :ok
  def engage(event) do
    GenServer.cast(__MODULE__, {:engage, event})
  end

  def init({:ok, token}) do
    {:ok, %{token: token}}
  end

  def handle_cast({:track, event, properties}, %{token: token} = state) do
    data = %{event: event,
             properties: Map.put(properties, :token, token)}
    |> Poison.encode!
    |> :base64.encode

    case HTTPoison.get(@track_endpoint, [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok
      other ->
        Logger.warn("Problem tracking Mixpanel event: #{inspect event}, #{inspect properties} Got: #{inspect other}")
    end

    {:noreply, state}
  end

  def handle_cast({:engage, event}, %{token: token} = state) do
    data = event
    |> Map.put(:"$token", token)
    |> Poison.encode!
    |> :base64.encode

    case HTTPoison.get(@engage_endpoint, [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok
      other ->
        Logger.warn("Problem tracking Mixpanel profile update: #{inspect event} Got: #{inspect other}")
    end

    {:noreply, state}
  end
end
