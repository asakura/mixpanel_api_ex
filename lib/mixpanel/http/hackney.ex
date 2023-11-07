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
            body :: binary,
            headers :: [{String.t(), binary}],
            opts :: keyword
          ) ::
            {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
            | {:error, String.t()}
    def post(url, body, headers, opts) do
      request(:post, url, headers, body, opts)
    end

    defp request(method, url, headers, body, opts) do
      opts =
        opts
        |> Keyword.split([:insecure])
        |> then(fn {opts, _} -> opts end)
        |> Enum.reduce([], fn
          {:insecure, true}, acc ->
            [:insecure | acc]
        end)

      case :hackney.request(method, url, headers, body, opts) do
        {:ok, status_code, headers} ->
          {:ok, status_code, headers, <<>>}

        {:ok, status_code, headers, client} ->
          max_length = Keyword.get(opts, :max_body_length, :infinity)

          case :hackney.body(client, max_length) do
            {:ok, body} ->
              {:ok, status_code, headers, body}

            {:error, reason} ->
              {:error, to_string(reason)}
          end

        {:ok, {:maybe_redirect, _status_code, _headers, _client}} ->
          {:error, "Redirect not supported"}

        {:error, reason} ->
          {:error, to_string(reason)}
      end
    end
  end
end
