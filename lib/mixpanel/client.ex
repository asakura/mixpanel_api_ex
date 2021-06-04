defmodule Mixpanel.Client do
  use GenServer

  @moduledoc false

  require Logger

  @track_path "/track"
  @engage_path "/engage"

  @max_attempts 3

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
      |> Jason.encode!()
      |> :base64.encode()

    perform(build_url(config, @track_path), params: [data: data])

    {:noreply, config}
  end

  def handle_cast({:engage, event}, %{token: token, active: true} = config) do
    data =
      event
      |> Map.put(:"$token", token)
      |> Jason.encode!()
      |> :base64.encode()

    perform(build_url(config, @engage_path), params: [data: data])

    {:noreply, config}
  end

  # No events submitted when env configuration is set to false.
  def handle_cast(_request, %{active: false} = config) do
    {:noreply, config}
  end

  defp build_url(%{base_url: base_url}, path) do
    base_url <> path
  end

  defp perform(url, data, max_attempts \\ @max_attempts)

  defp perform(_url, _data, 0) do
    :ignore
  end

  defp perform(url, data, max_attempts) do
    case Mixpanel.HTTPClient.get(url, [], data) do
      {:ok, %{status: 200, body: "1"}} ->
        :ok

      {:error, error} ->
        attempt = @max_attempts - (max_attempts - 1)

        Logger.warn(
          "Retrying Mixpanel http request (#{attempt}) : #{inspect(url)}, #{inspect(error)}"
        )

        perform(url, data, max_attempts - 1)
    end
  end
end
