defmodule Mixpanel.Mixfile do
  use Mix.Project

  @version "1.0.1"

  def project do
    [
      app: :mixpanel_api_ex,
      version: @version,
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "Mixpanel API",
      docs: [
        extras: ["README.md", "CHANGELOG.md"],
        source_ref: "v#{@version}",
        main: "Mixpanel",
        source_url: "https://github.com/agevio/mixpanel_api_ex"
      ]
    ]
  end

  def description do
    "Elixir client for the Mixpanel API."
  end

  def package do
    [
      maintainers: ["Mikalai Seva"],
      licenses: ["The MIT License"],
      links: %{"GitHub" => "https://github.com/agevio/mixpanel_api_ex"},
      files: ~w(mix.exs README.md CHANGELOG.md lib)
    ]
  end

  def application do
    [mod: {Mixpanel, []}, extra_applications: [:logger]]
  end

  defp deps do
    [
      {:httpoison, "~> 2.1", optional: true},
      {:jason, "~> 1.1"},
      {:credo, "~> 1.5", only: :dev},
      {:dialyxir, "~> 0.3", only: :dev},
      {:mock, "~> 0.3.6", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
