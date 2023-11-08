import Config

config :mixpanel_api_ex, MyApp.Mixpanel.US,
  base_url: "https://api.mixpanel.com",
  project_token: System.get_env("MIXPANEL_PROJECT_TOKEN"),
  http_adapter: Mixpanel.HTTP.HTTPC

config :mixpanel_api_ex, MyApp.Mixpanel.EU,
  base_url: "https://api-eu.mixpanel.com",
  project_token: System.get_env("MIXPANEL_PROJECT_TOKEN"),
  http_adapter: Mixpanel.HTTP.Hackney
