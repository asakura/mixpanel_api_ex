defmodule MixpanelTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mock

  defp mock() do
    [
      get: fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} end,
      post: fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} end
    ]
  end

  defp error_mock() do
    [get: fn _, _, _ -> {:error, %HTTPoison.Error{reason: "error"}} end]
  end

  defp retry_later_mock() do
    [get: fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 503}} end]
  end

  setup do
    start_supervised!({Mixpanel.Client, [active: true, token: ""]})

    {:ok, []}
  end

  test_with_mock "retries when HTTP client returns error", _, HTTPoison, [], error_mock() do
    capture_log(fn ->
      Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
    end)

    assert_called_exactly(HTTPoison.get("https://api.mixpanel.com/track", [], :_), 3)
  end

  test_with_mock "retries when API asks to retry later", _, HTTPoison, [], retry_later_mock() do
    capture_log(fn ->
      Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
    end)

    assert_called_exactly(HTTPoison.get("https://api.mixpanel.com/track", [], :_), 3)
  end

  describe "tracks an event" do
    test_with_mock "track/1", _, HTTPoison, [], mock() do
      Mixpanel.track("Signed up")

      :timer.sleep(50)

      assert_called(HTTPoison.get("https://api.mixpanel.com/track", [], :_))
    end

    test_with_mock "track/2", _, HTTPoison, [], mock() do
      Mixpanel.track("Signed up", %{"Referred By" => "friend"})

      :timer.sleep(50)

      assert_called(HTTPoison.get("https://api.mixpanel.com/track", [], :_))
    end

    test_with_mock "track/3", _, HTTPoison, [], mock() do
      Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")

      :timer.sleep(50)

      assert_called(HTTPoison.get("https://api.mixpanel.com/track", [], :_))

      Mixpanel.track(
        "Level Complete",
        %{"Level Number" => 9},
        distinct_id: "13793",
        time: 1_358_208_000,
        ip: "203.0.113.9"
      )

      :timer.sleep(50)

      assert_called(HTTPoison.get("https://api.mixpanel.com/track", [], :_))
    end
  end

  describe "tracks a profile update" do
    test_with_mock "engage/2", _, HTTPoison, [], mock() do
      Mixpanel.engage("13793", "$set")

      :timer.sleep(50)

      assert_called(HTTPoison.get("https://api.mixpanel.com/engage", [], :_))
    end

    test_with_mock "engage/3", _, HTTPoison, [], mock() do
      Mixpanel.engage("13793", "$set", %{"Address" => "1313 Mockingbird Lane"})

      :timer.sleep(50)

      assert_called(HTTPoison.get("https://api.mixpanel.com/engage", [], :_))
    end

    test_with_mock "engage/4", _, HTTPoison, [], mock() do
      Mixpanel.engage(
        "13793",
        "$set",
        %{"Address" => "1313 Mockingbird Lane"},
        ip: "123.123.123.123"
      )

      :timer.sleep(50)

      assert_called(HTTPoison.get("https://api.mixpanel.com/engage", [], :_))

      Mixpanel.engage(
        "13793",
        "$set",
        %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
        ip: "123.123.123.123"
      )

      :timer.sleep(50)

      assert_called(HTTPoison.get("https://api.mixpanel.com/engage", [], :_))
    end
  end

  test_with_mock "create an alias", _, HTTPoison, [], mock() do
    Mixpanel.create_alias("13793", "13794")

    :timer.sleep(50)

    assert_called(HTTPoison.post("https://api.mixpanel.com/track#identity-create-alias", :_, :_))
  end
end
