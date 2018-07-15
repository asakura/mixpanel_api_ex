defmodule MixpanelTest do
  use ExUnit.Case

  import Mock

  defp mock do
    [get: fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} end]
  end

  setup do
    pid = Process.whereis(Mixpanel.Client)

    {:ok, pid: pid}
  end

  test_with_mock "track an event", %{pid: pid}, HTTPoison, [], mock() do
    Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")

    :timer.sleep 50

    assert :meck.called(HTTPoison,
                        :get,
                        ["https://api.mixpanel.com/track",
                         [],
                         [params: [data: "eyJwcm9wZXJ0aWVzIjp7IlJlZmVycmVkIEJ5IjoiZnJpZW5kIiwidG9rZW4iOiIiLCJkaXN0aW5jdF9pZCI6IjEzNzkzIn0sImV2ZW50IjoiU2lnbmVkIHVwIn0="]]],
                        pid)


    Mixpanel.track("Level Complete", %{"Level Number" => 9}, distinct_id: "13793", time: 1358208000, ip: "203.0.113.9")

    :timer.sleep 50

    assert :meck.called(HTTPoison,
                        :get,
                        ["https://api.mixpanel.com/track",
                         [],
                         [params: [data: "eyJwcm9wZXJ0aWVzIjp7IkxldmVsIE51bWJlciI6OSwidG9rZW4iOiIiLCJ0aW1lIjoxMzU4MjA4MDAwLCJpcCI6IjIwMy4wLjExMy45IiwiZGlzdGluY3RfaWQiOiIxMzc5MyJ9LCJldmVudCI6IkxldmVsIENvbXBsZXRlIn0="]]],
                        pid)
  end


  test_with_mock "track a profile update", %{pid: pid}, HTTPoison, [], mock() do
    Mixpanel.engage("13793", "$set", %{"Address" => "1313 Mockingbird Lane"}, ip: "123.123.123.123")

    :timer.sleep 50

    assert :meck.called(HTTPoison,
                        :get,
                        ["https://api.mixpanel.com/engage",
                         [],
                         [params: [data: "eyIkc2V0Ijp7IkFkZHJlc3MiOiIxMzEzIE1vY2tpbmdiaXJkIExhbmUifSwiJHRva2VuIjoiIiwiJGlwIjoiMTIzLjEyMy4xMjMuMTIzIiwiJGRpc3RpbmN0X2lkIjoiMTM3OTMifQ=="]]],
                        pid)

    Mixpanel.engage("13793", "$set", %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}, ip: "123.123.123.123")

    :timer.sleep 50

    assert :meck.called(HTTPoison,
                        :get,
                        ["https://api.mixpanel.com/engage",
                         [],
                         [params: [data: "eyIkc2V0Ijp7IkJpcnRoZGF5IjoiMTk0OC0wMS0wMSIsIkFkZHJlc3MiOiIxMzEzIE1vY2tpbmdiaXJkIExhbmUifSwiJHRva2VuIjoiIiwiJGlwIjoiMTIzLjEyMy4xMjMuMTIzIiwiJGRpc3RpbmN0X2lkIjoiMTM3OTMifQ=="]]],
                        pid)
  end
end
