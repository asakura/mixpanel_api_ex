use Mix.Config

if Mix.env() == :test do
  config :mixpanel_api_ex,
    http_client: Mixpanel.HTTPClient.HTTPoison,
    active: true,
    token: "",
    base_url: "https://api.mixpanel.com"
end
