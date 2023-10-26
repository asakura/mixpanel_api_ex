defmodule MixpanelTest.Plug do
  @moduledoc false

  use Plug.Router

  import Plug.Conn

  plug(:match)
  plug(:dispatch)

  match _ do
    {:ok, body, conn} = read_body(conn)
    conn = fetch_query_params(conn)

    response =
      %{
        request_url: request_url(conn),
        http_protocol: get_http_protocol(conn) |> to_string(),
        body: body,
        method: conn.method,
        headers: conn.req_headers,
        # body_params: conn.body_params,
        query_params: conn.query_params
      }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response))
  end
end

defimpl Jason.Encoder, for: Tuple do
  def encode(data, opts) when is_tuple(data) do
    Jason.Encode.list(Tuple.to_list(data), opts)
  end
end
