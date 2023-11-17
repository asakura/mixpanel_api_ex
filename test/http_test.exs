defmodule MixpanelTest.HTTPTest do
  use ExUnit.Case
  use Machete

  alias Mixpanel.HTTP.{Hackney, HTTPC, NoOp}

  @base_url "https://localhost:40010"

  setup_all do
    child =
      {
        Bandit,
        plug: MixpanelTest.Plug,
        scheme: :https,
        ip: :loopback,
        port: 40_010,
        cipher_suite: :strong,
        otp_app: :mixpanel_api_ex,
        certfile: Path.join(__DIR__, "support/selfsigned.pem"),
        keyfile: Path.join(__DIR__, "support/selfsigned_key.pem")
      }

    start_supervised!(child)

    :ok
  end

  describe "NoOp adapter" do
    test "get/3" do
      response = NoOp.get("#{@base_url}/get_endpoint", [], insecure: true)

      assert response == {:ok, 200, [], "1"}
    end

    test "post/4" do
      response =
        NoOp.post(
          "#{@base_url}/post_endpoint",
          "body",
          [
            {"Content-Type", "application/x-www-form-urlencoded"}
          ],
          insecure: true
        )

      assert response == {:ok, 200, [], "1"}
    end
  end

  describe "HTTP adapters" do
    for adapter <- [Hackney, HTTPC] do
      test "#{adapter}.get/3" do
        case unquote(adapter).get("#{@base_url}/get_endpoint", [], insecure: true) do
          {:ok, 200, _headers, body} ->
            assert Jason.decode!(body)
                   ~> %{
                     "body" => "",
                     "method" => "GET",
                     "query_params" => map(size: 0),
                     "request_headers" =>
                       list(min: 1, elements: list(min: 2, max: 2, elements: string())),
                     "request_path" => "/get_endpoint"
                   }

          {:ok, status, _headers, _body} ->
            refute "Expected 200, got #{status}"

          {:error, error} ->
            refute "Expected response, got #{inspect(error)}"
        end
      end

      test "#{adapter}.post/4" do
        case unquote(adapter).post(
               "#{@base_url}/post_endpoint",
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
                     "method" => "POST",
                     "query_params" => map(size: 0),
                     "request_headers" =>
                       list(min: 1, elements: list(min: 2, max: 2, elements: string())),
                     "request_path" => "/post_endpoint"
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
