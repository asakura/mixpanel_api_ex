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

      opts =
        opts
        |> Keyword.split([:params, :insecure])
        |> then(fn {opts, _} -> opts end)
        |> Enum.reduce([], fn
          {:params, value} = params, acc when not is_nil(value) ->
            [params | acc]

          {:insecure, true}, acc ->
            [{:ssl, [{:verify, :verify_none}]} | acc]
        end)

      {params, http_opts} = Keyword.pop(opts, :params, nil)

      case do_request(
             method,
             build_url(url, params),
             prepare_headers(headers),
             content_type,
             payload,
             [{:autoredirect, false} | http_opts]
           ) do
        {:ok, {{_, status_code, _}, headers, body}} ->
          {:ok, status_code, format_headers(headers), body}
      end
    end

    defp do_request(:get, url, headers, _content_type, _payload, http_opts) do
      :httpc.request(:get, {url, headers}, http_opts, [])
    end

    defp do_request(:post, url, headers, content_type, payload, http_opts) do
      :httpc.request(:post, {url, headers, content_type, payload}, http_opts, [])
    end

    defp format_headers(headers) do
      for [key, value] <- headers do
        {to_string(key), to_string(value)}
      end
    end

    defp prepare_headers(headers) do
      for {key, value} <- headers do
        {to_charlist(key), to_charlist(value)}
      end
    end

    defp build_url(url, nil) do
      url
    end

    defp build_url(url, data: data) do
      "#{url}?data=#{data}"
    end
  end
end
