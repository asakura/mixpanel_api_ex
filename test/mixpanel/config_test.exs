defmodule Mixpanel.ConfigTest do
  use ExUnit.Case, async: true
  use Machete

  alias Mixpanel.Config

  test "client/2 put default options" do
    assert Config.client(MyApp.Mixpanel, project_token: "token")
           ~> in_any_order([
             {:name, MyApp.Mixpanel},
             {:base_url, "https://api.mixpanel.com"},
             {:http_adapter, Mixpanel.HTTP.HTTPC},
             {:project_token, "token"}
           ])
  end
end
