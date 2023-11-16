defmodule MixpanelTest.Plug do
  @moduledoc false

  use Plug.Router

  import Plug.Conn

  plug(:match)
  plug(:dispatch)

  match _ do
    {:ok, body, conn} = read_body(conn)
    conn = fetch_query_params(conn)

    response = %{
      body: body,
      method: conn.method,
      query_params: conn.query_params,
      request_headers: conn.req_headers,
      request_path: conn.request_path
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response))
  end
end

defimpl Jason.Encoder, for: Tuple do
  @spec encode(tuple, Jason.Encode.opts()) :: iodata | {:error, EncodeError.t() | Exception.t()}
  def encode(data, opts) when is_tuple(data) do
    Jason.Encode.list(Tuple.to_list(data), opts)
  end
end
