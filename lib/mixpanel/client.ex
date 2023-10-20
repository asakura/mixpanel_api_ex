defmodule Mixpanel.Client do
  use GenServer

  @moduledoc """
  Mixpanel API Client GenServer.
  """

  require Logger

  @base_url "https://api.mixpanel.com"
  @track_endpoint "/track"
  @engage_endpoint "/engage"
  @alias_endpoint "/track#identity-create-alias"
  @max_attempts 3

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    {opts, gen_server_opts} = Keyword.split(init_args, [:token, :active, :base_url])

    GenServer.start_link(__MODULE__, opts, gen_server_opts)
  end

  def child_spec(init_args) do
    init_args =
      init_args
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.put_new(:base_url, @base_url)

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_args]}
    }
  end

  @doc """
  Tracks a event

  See `Mixpanel.track/3`
  """
  @spec track(String.t(), map) :: :ok
  def track(event, properties) do
    GenServer.cast(__MODULE__, {:track, event, properties})
  end

  @doc """
  Updates a user profile.

  See `Mixpanel.engage/4`.
  """
  @spec engage(map | [map]) :: :ok
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

    case perform(state.base_url <> @track_endpoint, data) do
      :ok ->
        :ok

      _ ->
        Logger.warning(
          "Problem tracking Mixpanel event: #{inspect(event)}, #{inspect(properties)}"
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

    case perform(state.base_url <> @engage_endpoint, data) do
      :ok ->
        :ok

      _ ->
        Logger.warning("Problem tracking Mixpanel profile update: #{inspect(event)}")
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

  defp put_token(events, token) when is_list(events),
    do: Enum.map(events, &put_token(&1, token))

  defp put_token(event, token),
    do: Map.put(event, :"$token", token)

  defp perform(url, data, max_attempts \\ @max_attempts)

  defp perform(_url, _data, 0) do
    :ignore
  end

  defp perform(url, data, max_attempts) do
    case HTTPoison.get(url, [], params: [data: data]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} ->
        :ok

      other ->
        attempt = @max_attempts - (max_attempts + 1)

        case other do
          {:ok, %HTTPoison.Response{} = response} ->
            Logger.warning(
              "Retrying Mixpanel request: attempt=#{attempt}, url=#{inspect(url)}, response=#{inspect(response)}"
            )

          {:error, reason} ->
            Logger.warning(
              "Retrying Mixpanel request: attempt=#{attempt}, url=#{inspect(url)}, error=#{inspect(reason)}"
            )
        end

        perform(url, data, max_attempts - 1)
    end
  end
end
