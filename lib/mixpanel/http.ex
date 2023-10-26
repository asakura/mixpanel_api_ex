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
              body :: term,
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
          headers :: [{String.t(), binary}],
          body :: term,
          opts :: keyword
        ) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | :ignore
  def post(url, body, headers \\ [], opts \\ []) do
    client = impl()
    retry(url, fn -> client.post(url, body, headers, opts) end, @max_retries)
  end

  @spec impl() :: module
  def impl() do
    Application.get_env(:mixpanel_api_ex, :http_adapter, Mixpanel.HTTP.HTTPoison)
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
            Logger.warning(
              "Retrying Mixpanel request: attempt=#{attempt}, url=#{inspect(url)}, status=#{inspect(status)}"
            )

          {:error, reason} ->
            Logger.warning(
              "Retrying Mixpanel request: attempt=#{attempt}, url=#{inspect(url)}, error=#{inspect(reason)}"
            )
        end

        retry(url, fun, attempts_left - 1)
    end
  end
end

defmodule Mixpanel.HTTP.HTTPoison do
  @moduledoc """
  Adapter for [HTTPoison](https://github.com/edgurgel/httpoison).
  """

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
  def post(url, body, headers, _opts) do
    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: status, headers: headers, body: body}} ->
        {:ok, status, headers, body}

      {:error, %HTTPoison.Error{} = error} ->
        {:error, HTTPoison.Error.message(error)}
    end
  end
end

if Code.ensure_loaded?(:hackney) do
  defmodule Mixpanel.HTTP.Hackney do
    @moduledoc """
    Adapter for [hackney](https://github.com/benoitc/hackney).

    Remember to add `{:hackney, "~> 1.20"}` to dependencies (and `:hackney` to applications in `mix.exs`).

    ## Examples

    ```
    # set globally in config/config.exs
    config :mixpanel_api_ex, :http_adapter, Mixpanel.HTTP.Hackney
    ```

    ## Adapter specific options

    - `:max_body_length` - Max response body size in bytes. Actual response may
      be bigger because hackney stops after the last chunk that surpasses
      `:max_body_length`. Defaults to `:infinity`.
    """

    @behaviour Mixpanel.HTTP

    @impl Mixpanel.HTTP
    @spec get(url :: String.t(), headers :: [{String.t(), binary}], opts :: keyword) ::
            {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
            | {:error, String.t()}
    def get(url, headers, opts) do
      request(:get, url, headers, "", opts)
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
      request(:post, url, headers, body, opts)
    end

    defp request(method, url, headers, payload, opts) do
      case :hackney.request(method, url, headers, payload, opts) do
        {:ok, status_code, headers} ->
          {:ok, status_code, headers, <<>>}

        {:ok, status_code, headers, client} ->
          max_length = Keyword.get(opts, :max_body_length, :infinity)

          case :hackney.body(client, max_length) do
            {:ok, body} ->
              {:ok, status_code, headers, body}

            {:error, _reason} = err ->
              err
          end

        {:ok, {:maybe_redirect, _status_code, _headers, _client}} ->
          {:error, "Redirect not supported"}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
