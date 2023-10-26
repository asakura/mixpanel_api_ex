defmodule MixpanelTest.HTTPTest do
  use ExUnit.Case
  use Machete

  setup_all do
    child =
      {
        Bandit,
        plug: MixpanelTest.Plug,
        scheme: :https,
        port: 40010,
        cipher_suite: :strong,
        otp_app: :mixpanel_api_ex,
        certfile: "priv/cert/selfsigned.pem",
        keyfile: "priv/cert/selfsigned_key.pem"
      }

    start_supervised!(child)

    :ok
  end

  describe "HTTPoison adapter" do
    for adapter <- [Mixpanel.HTTP.Hackney, Mixpanel.HTTP.HTTPC] do
      test "#{adapter}.get/3" do
        case unquote(adapter).get("https://localhost:40010/get_endpoint", [], insecure: true) do
          {:ok, 200, _headers, body} ->
            assert Jason.decode!(body)
                   ~> %{
                     "body" => "",
                     "headers" =>
                       list(min: 1, elements: list(min: 2, max: 2, elements: string())),
                     "http_protocol" => string(starts_with: "HTTP"),
                     "method" => "GET",
                     "query_params" => map(size: 0),
                     "request_url" => string(ends_with: "/get_endpoint")
                   }

          {:ok, status, _headers, _body} ->
            refute "Expected 200, got #{status}"

          {:error, error} ->
            refute "Expected response, got #{inspect(error)}"
        end
      end

      test "#{adapter}.post/4" do
        case unquote(adapter).post(
               "https://localhost:40010/post_endpoint",
               "body",
               [
                 {"Content-Type", "application/x-www-form-urlencoded"}
               ],
               insecure: true
             ) do
          {:ok, 200, _headers, body} ->
            assert Jason.decode!(body)
                   ~> %{
                     "body" => "body",
                     "headers" =>
                       list(min: 1, elements: list(min: 2, max: 2, elements: string())),
                     "http_protocol" => string(starts_with: "HTTP"),
                     "method" => "POST",
                     "query_params" => map(size: 0),
                     "request_url" => string(ends_with: "/post_endpoint")
                   }

          {:ok, status, _headers, _body} ->
            refute "Expected 200, got #{status}"

          {:error, error} ->
            refute "Expected 200, got #{inspect(error)}"
        end
      end
    end
  end
end
