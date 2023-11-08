import Config

config :mixpanel_api_ex, MixpanelTest,
  project_token: "token",
  base_url: "https://api.mixpanel.com",
  http_adapter: MixpanelTest.HTTP.Mock

config :mixpanel_api_ex, MixpanelTest.Using,
  project_token: "token",
  base_url: "https://api.mixpanel.com",
  http_adapter: MixpanelTest.HTTP.Mock
