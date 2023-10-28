Application.load(:mixpanel_api_ex)

for app <- Application.spec(:mixpanel_api_ex, :applications) do
  Application.ensure_all_started(app)
end

Mox.defmock(Mixpanel.HTTP.Mock, for: Mixpanel.HTTP)
Application.put_env(:mixpanel_api_ex, :http_adapter, Mixpanel.HTTP.Mock)

ExUnit.start()
