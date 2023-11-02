import Config

config :mixpanel_api_ex, :clients, [MixpanelTest]

config :mixpanel_api_ex, MixpanelTest,
  project_token: "token",
  base_url: "https://api.mixpanel.com",
  http_adapter: MixpanelTest.HTTP.Mock
