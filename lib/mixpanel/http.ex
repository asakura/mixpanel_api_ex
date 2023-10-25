defmodule Mixpanel.HTTP do
  require Logger

  @max_retries 3

  @callback get(url :: String.t(), headers :: [{String.t(), binary}], opts :: keyword) ::
              {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
              | {:error, String.t()}

  @callback post(
              url :: String.t(),
              body :: term,
              headers :: [{String.t(), binary}],
              opts :: keyword
            ) ::
              {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
              | {:error, String.t()}

  @spec get(url :: String.t(), headers :: [{String.t(), binary}], opts :: keyword) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | :ignore
  def get(url, headers, opts) do
    client = client()
    retry(url, fn -> client.get(url, headers, opts) end, @max_retries)
  end

  @spec post(
          url :: String.t(),
          headers :: [{String.t(), binary}],
          body :: term,
          opts :: keyword
        ) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | :ignore
  def post(url, body, headers, opts) do
    client = client()
    retry(url, fn -> client.post(url, body, headers, opts) end, @max_retries)
  end

  def client() do
    Application.get_env(:mixpanel_api_ex, :http_client, Mixpanel.HTTP.HTTPoison)
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

      {:error, reason} ->
        attempt = @max_retries - (attempts_left + 1)

        Logger.warning(
          "Retrying Mixpanel request: attempt=#{attempt}, url=#{inspect(url)}, error=#{inspect(reason)}"
        )

        retry(url, fun, attempts_left - 1)
    end
  end
end

defmodule Mixpanel.HTTP.HTTPoison do
  @behaviour Mixpanel.HTTP

  @impl Mixpanel.HTTP
  @spec get(url :: String.t(), headers :: [{String.t(), binary}], opts :: keyword) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | {:error, String.t()}
  def get(url, headers, opts) do
    case HTTPoison.get(url, headers, opts) do
      {:ok, %HTTPoison.Response{status_code: status, headers: headers, body: body}} ->
        {:ok, status, headers, body}

      {:error, %HTTPoison.Error{} = error} ->
        {:error, HTTPoison.Error.message(error)}
    end
  end

  @impl Mixpanel.HTTP
  @spec post(
          url :: String.t(),
          headers :: [{String.t(), binary}],
          body :: term,
          opts :: keyword
        ) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | {:error, String.t()}
  def post(url, body, headers, opts) do
    case HTTPoison.post(url, body, headers, opts) do
      {:ok, %HTTPoison.Response{status_code: status, headers: headers, body: body}} ->
        {:ok, status, headers, body}

      {:error, %HTTPoison.Error{} = error} ->
        {:error, HTTPoison.Error.message(error)}
    end
  end
end
