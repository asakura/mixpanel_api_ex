defmodule MixpanelTest do
  use ExUnit.Case

  import Mock

  defp mock() do
    [get: fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} end]
  end

  setup do
    # start_supervised!(Mixpanel.Client.child_spec(active: true, token: ""))
    start_supervised!({Mixpanel.Client, [active: true, token: ""]})

    {:ok, []}
  end

  end

  test_with_mock "track an event", _, HTTPoison, [], mock() do
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

  test_with_mock "track a profile update", _, HTTPoison, [], mock() do
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
