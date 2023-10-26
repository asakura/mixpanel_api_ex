Mox.defmock(Mixpanel.HTTP.Mock, for: Mixpanel.HTTP)
Application.put_env(:mixpanel_api_ex, :http_adapter, Mixpanel.HTTP.Mock)

ExUnit.start()
