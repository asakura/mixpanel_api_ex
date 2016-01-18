use Mix.Config

if Mix.env == :test do
  config :mixpanel_api_ex, token: ""
end
