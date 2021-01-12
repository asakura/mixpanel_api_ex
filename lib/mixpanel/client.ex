defmodule Mixpanel.Client do
  use GenServer

  @moduledoc """


  """

  require Logger

  @track_path "/track"
  @engage_path "/engage"

  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, arg}
    }
  end

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

  def init({:ok, config}) do
    {:ok, Enum.into(config, %{})}
  end

  def handle_cast({:track, event, properties}, %{token: token, active: true} = config) do
    data =
      %{event: event, properties: Map.put(properties, :token, token)}
      |> Poison.encode!()
      |> :base64.encode()

    case HTTPoison.get(build_url(config, @track_path), [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        Logger.warn(
          "Problem tracking Mixpanel event: #{inspect(event)}, #{inspect(properties)} Got: #{
            inspect(other)
          }"
        )
    end

    {:noreply, config}
  end

  def handle_cast({:engage, event}, %{token: token, active: true} = config) do
    data =
      event
      |> Map.put(:"$token", token)
      |> Poison.encode!()
      |> :base64.encode()

    case HTTPoison.get(build_url(config, @engage_path), [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        Logger.warn(
          "Problem tracking Mixpanel profile update: #{inspect(event)} Got: #{inspect(other)}"
        )
    end

    {:noreply, config}
  end

  # No events submitted when env configuration is set to false.
  def handle_cast(_request, %{active: false} = config) do
    {:noreply, config}
  end

  defp build_url(%{base_url: base_url}, path) do
    base_url <> path
  end
end
