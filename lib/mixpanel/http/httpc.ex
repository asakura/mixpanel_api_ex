if Code.ensure_loaded?(:httpc) do
  defmodule Mixpanel.HTTP.HTTPC do
    @moduledoc """
    Adapter for [httpc](http://erlang.org/doc/man/httpc.html).

    This is the default adapter.
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
            body :: binary,
            headers :: [{String.t(), binary}],
            opts :: keyword
          ) ::
            {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
            | {:error, String.t()}
    def post(url, body, headers, opts) do
      request(:post, url, headers, body, opts)
    end

    defp request(method, url, headers, payload, opts) do
      content_type =
        case List.keyfind(headers, "Content-Type", 0) do
          {_, value} -> to_charlist(value)
          _ -> nil
        end

      http_opts =
        opts
        |> Keyword.split([:insecure])
        |> then(fn {opts, _} -> opts end)
        |> Enum.reduce([], fn
          {:insecure, true}, acc ->
            [{:ssl, [{:verify, :verify_none}]} | acc]
        end)

      case do_request(
             method,
             # Erlang 22 comparability layer: httpc wants a charlist as URL
             # Remove it when OTP 22 support is dropped
             String.to_charlist(url),
             prepare_headers(headers),
             content_type,
             payload,
             [{:autoredirect, false} | http_opts]
           ) do
        {:ok, {{_, status_code, _}, headers, body}} ->
          {:ok, status_code, format_headers(headers), to_string(body)}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    end

    defp do_request(:get, url, headers, _content_type, _payload, http_opts) do
      :httpc.request(:get, {url, headers}, http_opts, [])
    end

    defp do_request(:post, url, headers, content_type, payload, http_opts) do
      :httpc.request(:post, {url, headers, content_type, payload}, http_opts, [])
    end

    defp format_headers(headers) do
      for {key, value} <- headers do
        {to_string(key), to_string(value)}
      end
    end

    defp prepare_headers(headers) do
      for {key, value} <- headers do
        {to_charlist(key), to_charlist(value)}
      end
    end
  end
end
