defmodule MixpanelTest.Test do
  use ExUnit.Case
  use Machete

  import ExUnit.CaptureLog
  import Mox

  setup :verify_on_exit!

  setup do
    pid =
      start_supervised!(
        {Mixpanel.Client,
         [
           base_url: "http://localhost:4000",
           http_adapter: MixpanelTest.HTTP.Mock,
           name: MixpanelTest,
           project_token: ""
         ]}
      )

    MixpanelTest.HTTP.Mock
    |> allow(self(), pid)

    {:ok, client: pid}
  end

  test "retries when HTTP client returns error" do
    MixpanelTest.HTTP.Mock
    |> expect(:get, 3, fn _url, _headers, _opts ->
      {:error, ""}
    end)

    capture_log(fn ->
      MixpanelTest.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
    end)
  end

  test "retries when API asks to retry later" do
    MixpanelTest.HTTP.Mock
    |> expect(:get, 3, fn _url, _headers, _opts -> {:ok, 503, [], ""} end)

    capture_log(fn ->
      MixpanelTest.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
    end)
  end

  describe "tracks an event" do
    setup do
      MixpanelTest.HTTP.Mock
      |> expect(:get, fn url, _headers, _opts ->
        uri = parse(url)

        assert uri.path == "/track"
        assert uri.query ~> string(starts_with: "data=")

        {:ok, 200, [], "1"}
      end)

      :ok
    end

    test "track/1" do
      MixpanelTest.track("Signed up")
      :timer.sleep(50)
    end

    test "track/2" do
      MixpanelTest.track("Signed up", %{"Referred By" => "friend"})
      :timer.sleep(50)
    end

    test "track/3" do
      MixpanelTest.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
    end

    test "track/3 with IP string" do
      MixpanelTest.track("Level Complete", %{"Level Number" => 9},
        distinct_id: "13793",
        ip: "203.0.113.9"
      )

      :timer.sleep(50)
    end

    test "track/3 with IP tuple" do
      MixpanelTest.track("Level Complete", %{"Level Number" => 9},
        distinct_id: "13793",
        ip: {203, 0, 113, 9}
      )

      :timer.sleep(50)
    end
  end

  describe "tracks an event with time" do
    setup do
      MixpanelTest.HTTP.Mock
      |> expect(:get, fn url, _headers, _opts ->
        uri = parse(url)

        assert uri.path == "/track"
        assert uri.query ~> string(starts_with: "data=")

        data =
          uri.query
          |> URI.decode_query()
          |> then(& &1["data"])
          |> :base64.decode()
          |> Jason.decode!()

        assert data
               ~> %{
                 "event" => string(),
                 "properties" => %{
                   "time" => 1_358_208_000,
                   "token" => string()
                 }
               }

        {:ok, 200, [], "1"}
      end)

      :ok
    end

    test "track/3 handles NaiveDatetime" do
      MixpanelTest.track("Level Complete", %{}, time: ~N[2013-01-15 00:00:00])
      :timer.sleep(50)
    end

    test "track/3 handles Datetime" do
      MixpanelTest.track("Level Complete", %{}, time: ~U[2013-01-15 00:00:00Z])
      :timer.sleep(50)
    end

    test "track/3 handles Unix timestamps" do
      MixpanelTest.track("Level Complete", %{}, time: 1_358_208_000)
      :timer.sleep(50)
    end

    test "track/3 handles Erlang calendar timestamps" do
      MixpanelTest.track("Level Complete", %{}, time: {{2013, 01, 15}, {00, 00, 00}})
      :timer.sleep(50)
    end

    test "track/3 handles Erlang timestamps" do
      MixpanelTest.track("Level Complete", %{}, time: {1358, 208_000, 0})
      :timer.sleep(50)
    end
  end

  describe "tracks a profile update" do
    setup do
      MixpanelTest.HTTP.Mock
      |> expect(:get, fn url, _headers, _opts ->
        uri = parse(url)

        assert uri.path == "/engage"
        assert uri.query ~> string(starts_with: "data=")

        {:ok, 200, [], "1"}
      end)

      :ok
    end

    # test "engage/2" do
    #   MixpanelTest.engage("13793", "$set")
    #   :timer.sleep(50)
    # end

    test "engage/3" do
      MixpanelTest.engage("13793", "$set", %{"Address" => "1313 Mockingbird Lane"})
      :timer.sleep(50)
    end

    test "engage/4 with IP string" do
      MixpanelTest.engage(
        "13793",
        "$set",
        %{"Address" => "1313 Mockingbird Lane"},
        ip: "123.123.123.123"
      )

      :timer.sleep(50)
    end

    test "engage/4 with IP tuple" do
      MixpanelTest.engage(
        "13793",
        "$set",
        %{"Address" => "1313 Mockingbird Lane"},
        ip: {123, 123, 123, 123}
      )

      :timer.sleep(50)
    end
  end

  describe "creates an identity alias" do
    setup do
      MixpanelTest.HTTP.Mock
      |> expect(:post, fn url, body, _headers, _opts ->
        uri = parse(url)

        assert uri.path == "/track"
        assert uri.fragment == "identity-create-alias"
        assert uri.query == nil
        assert body ~> string(starts_with: "data=")

        {:ok, 200, [], "1"}
      end)

      :ok
    end

    test "create an alias" do
      MixpanelTest.create_alias("13793", "13794")
      :timer.sleep(50)
    end
  end

  test "__using__/1" do
    ast =
      quote do
        use Mixpanel
      end

    assert {:module, _module, _bytecode, _exports} =
             Module.create(MixpanelTest.Using, ast, Macro.Env.location(__ENV__))

    # credo:disable-for-next-line
    assert apply(MixpanelTest.Using, :__info__, [:functions])
           ~> in_any_order([
             {:track, 1},
             {:track, 2},
             {:track, 3},
             {:engage, 1},
             {:engage, 2},
             {:engage, 3},
             {:engage, 4},
             {:create_alias, 2}
           ])
  end

  # Elixir 1.12 comparability layer
  # Remove when support for 1.12 is dropped
  defp parse(uri) do
    unquote(
      if function_exported?(URI, :new, 1) do
        quote do
          {:ok, uri} = URI.new(var!(uri))
          uri
        end
      else
        quote do
          URI.parse(var!(uri))
        end
      end
    )
  end
end
