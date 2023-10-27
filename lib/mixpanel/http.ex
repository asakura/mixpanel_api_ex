defmodule Mixpanel.HTTP do
  @moduledoc """
  Adapter specification for HTTP clients and API for accessing them.
  """

  require Logger

  @max_retries 3

  @callback get(url :: String.t(), headers :: [{String.t(), binary}], opts :: keyword) ::
              {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
              | {:error, String.t()}

  @callback post(
              url :: String.t(),
              body :: binary,
              headers :: [{String.t(), binary}],
              opts :: keyword
            ) ::
              {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
              | {:error, String.t()}

  @spec get(url :: String.t(), headers :: [{String.t(), binary}], opts :: keyword) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | :ignore
  def get(url, headers \\ [], opts \\ []) do
    client = impl()
    retry(url, fn -> client.get(url, headers, opts) end, @max_retries)
  end

  @spec post(
          url :: String.t(),
          payload :: binary,
          headers :: [{String.t(), binary}],
          opts :: keyword
        ) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | :ignore
  def post(url, payload, headers \\ [], opts \\ []) do
    client = impl()
    retry(url, fn -> client.post(url, payload, headers, opts) end, @max_retries)
  end

  @spec impl() :: module
  def impl() do
    Application.get_env(:mixpanel_api_ex, :http_adapter, Mixpanel.HTTP.HTTPC)
  end

  @spec retry(String.t(), (-> {:ok, any, any, any} | {:error, String.t()}), pos_integer) ::
          {:ok, any, any, any} | :ignore
  defp retry(_url, _fun, 0) do
    :ignore
  end

  defp retry(url, fun, attempts_left) do
    case fun.() do
      {:ok, 200, _headers, "1"} = ok ->
        ok

      other ->
        attempt = @max_retries - (attempts_left + 1)

        case other do
          {:ok, status, _headers, _body} ->
            Logger.warning(%{
              message: "Retrying request",
              attempt: attempt,
              url: url,
              status: status
            })

          {:error, reason} ->
            Logger.warning(%{
              message: "Retrying request",
              attempt: attempt,
              url: url,
              error: reason
            })
        end

        retry(url, fun, attempts_left - 1)
    end
  end
end
