import Config

config = "#{Mix.env()}.exs"

File.exists?("config/#{config}") && import_config(config)
