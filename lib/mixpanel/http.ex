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

  @spec get(
          client :: module,
          url :: String.t(),
          headers :: [{String.t(), binary}],
          opts :: keyword
        ) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | {:error, String.t()}
  def get(client, url, headers, opts) do
    {params, opts} = Keyword.pop(opts, :params, nil)
    retry(url, fn -> client.get(build_url(url, params), headers, opts) end, @max_retries)
  end

  @spec post(
          client :: module,
          url :: String.t(),
          payload :: binary,
          headers :: [{String.t(), binary}],
          opts :: keyword
        ) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | {:error, String.t()}
  def post(client, url, payload, headers, opts) do
    retry(url, fn -> client.post(url, payload, headers, opts) end, @max_retries)
  end

  @spec retry(String.t(), (-> {:ok, any, any, any} | {:error, String.t()}), non_neg_integer) ::
          {:ok, any, any, any} | {:error, String.t()}
  defp retry(_url, _fun, 0) do
    {:error, "Max retries reached"}
  end

  defp retry(url, fun, attempts_left) do
    case fun.() do
      {:ok, 200, _headers, "1"} = ok ->
        ok

      other ->
        attempts_left = attempts_left - 1

        case other do
          {:ok, status, _headers, _body} ->
            Logger.warning(%{
              message: "Retrying request",
              attempts_left: attempts_left,
              url: url,
              status: status
            })

          {:error, reason} = err ->
            Logger.warning(%{
              message: "Retrying request",
              attempts_left: attempts_left,
              url: url,
              error: reason
            })

            err
        end

        retry(url, fun, attempts_left)
    end
  end

  defp build_url(url, nil), do: url
  defp build_url(url, data: data), do: "#{url}?#{URI.encode_query(data: data)}"
end
