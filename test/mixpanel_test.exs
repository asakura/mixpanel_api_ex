defmodule MixpanelTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mock

  defp mock do
    [get: fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 200, body: "1"}} end]
  end

  setup do
    pid = Process.whereis(Mixpanel.Client)

    {:ok, pid: pid}
  end

  test_with_mock "track an event", %{pid: _pid}, HTTPoison, [], mock() do
    Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")

    :timer.sleep(50)

    assert called(
             HTTPoison.get(
               "https://api.mixpanel.com/track",
               [],
               params: [
                 data:
                   "eyJldmVudCI6IlNpZ25lZCB1cCIsInByb3BlcnRpZXMiOnsiZGlzdGluY3RfaWQiOiIxMzc5MyIsInRva2VuIjoiIiwiUmVmZXJyZWQgQnkiOiJmcmllbmQifX0="
               ]
             )
           )

    Mixpanel.track(
      "Level Complete",
      %{"Level Number" => 9},
      distinct_id: "13793",
      time: 1_358_208_000,
      ip: "203.0.113.9"
    )

    :timer.sleep(50)

    assert called(
             HTTPoison.get(
               "https://api.mixpanel.com/track",
               [],
               params: [
                 data:
                   "eyJldmVudCI6IkxldmVsIENvbXBsZXRlIiwicHJvcGVydGllcyI6eyJkaXN0aW5jdF9pZCI6IjEzNzkzIiwiaXAiOiIyMDMuMC4xMTMuOSIsInRpbWUiOjEzNTgyMDgwMDAsInRva2VuIjoiIiwiTGV2ZWwgTnVtYmVyIjo5fX0="
               ]
             )
           )
  end

  def retry do
    [
      get: fn _, _, _ -> {:error, %HTTPoison.Error{reason: "error"}} end
    ]
  end

  test_with_mock "works with retries", %{pid: pid}, HTTPoison, [], retry() do
    capture_log(fn ->
      Mixpanel.track("Signed up", %{"Referred By" => "friend"}, distinct_id: "13793")
      :timer.sleep(50)
      Process.exit(pid, :kill)
    end)

    assert_called_exactly(
      HTTPoison.get(
        "https://api.mixpanel.com/track",
        [],
        params: [
          data:
            "eyJldmVudCI6IlNpZ25lZCB1cCIsInByb3BlcnRpZXMiOnsiZGlzdGluY3RfaWQiOiIxMzc5MyIsInRva2VuIjoiIiwiUmVmZXJyZWQgQnkiOiJmcmllbmQifX0="
        ]
      ),
      3
    )
  end

  test_with_mock "track a profile update", %{pid: _pid}, HTTPoison, [], mock() do
    Mixpanel.engage(
      "13793",
      "$set",
      %{"Address" => "1313 Mockingbird Lane"},
      ip: "123.123.123.123"
    )

    :timer.sleep(50)

    assert called(
             HTTPoison.get(
               "https://api.mixpanel.com/engage",
               [],
               params: [
                 data:
                   "eyIkZGlzdGluY3RfaWQiOiIxMzc5MyIsIiRpcCI6IjEyMy4xMjMuMTIzLjEyMyIsIiR0b2tlbiI6IiIsIiRzZXQiOnsiQWRkcmVzcyI6IjEzMTMgTW9ja2luZ2JpcmQgTGFuZSJ9fQ=="
               ]
             )
           )

    Mixpanel.engage(
      "13793",
      "$set",
      %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
      ip: "123.123.123.123"
    )

    :timer.sleep(50)

    assert called(
             HTTPoison.get(
               "https://api.mixpanel.com/engage",
               [],
               params: [
                 data:
                   "eyIkZGlzdGluY3RfaWQiOiIxMzc5MyIsIiRpcCI6IjEyMy4xMjMuMTIzLjEyMyIsIiR0b2tlbiI6IiIsIiRzZXQiOnsiQWRkcmVzcyI6IjEzMTMgTW9ja2luZ2JpcmQgTGFuZSIsIkJpcnRoZGF5IjoiMTk0OC0wMS0wMSJ9fQ=="
               ]
             )
           )
  end
end
