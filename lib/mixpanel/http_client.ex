defmodule Mixpanel.HTTPClient do
  @moduledoc """
  Behaviour for the http mixpanel client
  """
  @callback get(url :: String.t(), headers :: [{binary(), binary()}], opts :: Keyword.list()) ::
              {:ok,
               %{
                 status: 200..599,
                 headers: [{binary(), binary()}],
                 body: binary()
               }}
              | {:error, term()}

  def get(url, headers, opts) do
    client().get(url, headers, opts)
  end

  def client do
    Application.get_env(:mixpanel_api_ex, :http_client)
  end
end

defmodule Mixpanel.HTTPClient.HTTPoison do
  @moduledoc false
  @behaviour Mixpanel.HTTPClient

  @impl true
  def get(url, headers, opts) do
    case HTTPoison.get(url, headers, opts) do
      {:ok, %HTTPoison.Response{status_code: status, body: body, headers: headers}} ->
        {:ok,
         %{
           status: status,
           headers: headers,
           body: body
         }}

      {:error, %HTTPoison.Error{} = error} ->
        {:error, HTTPoison.Error.message(error)}
    end
  end
end
