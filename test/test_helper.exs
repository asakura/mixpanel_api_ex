Application.load(:mixpanel_api_ex)

for app <- Application.spec(:mixpanel_api_ex, :applications) do
  Application.ensure_all_started(app)
end

Mox.defmock(MixpanelTest.HTTP.Mock, for: Mixpanel.HTTP)

Application.put_env(:mixpanel_api_ex, :clients, [MixpanelTest])

Application.put_env(:mixpanel_api_ex, MixpanelTest,
  project_token: "token",
  base_url: "https://api.mixpanel.com",
  http_adapter: MixpanelTest.HTTP.Mock
)

ExUnit.start()
