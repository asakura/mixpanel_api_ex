defmodule Mixpanel.HTTP.NoOp do
  @moduledoc """
  A fake adapter which primary should be used for testing purposes.
  """

  @behaviour Mixpanel.HTTP

  @impl Mixpanel.HTTP
  @spec get(url :: String.t(), headers :: [{String.t(), binary}], opts :: keyword) ::
          {:ok, status :: 200..599, headers :: [{String.t(), binary}], body :: term}
          | {:error, String.t()}
  def get(_url, _headers, _opts) do
    {:ok, 200, [], "1"}
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
  def post(_url, _body, _headers, _opts) do
    {:ok, 200, [], "1"}
  end
end
