Application.load(:mixpanel_api_ex)

for app <- Application.spec(:mixpanel_api_ex, :applications) do
  Application.ensure_all_started(app)
end

Mox.defmock(MixpanelTest.HTTP.Mock, for: Mixpanel.HTTP)

ExUnit.start()
