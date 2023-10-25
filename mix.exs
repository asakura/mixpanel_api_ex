defmodule Mixpanel.Mixfile do
  use Mix.Project

  @version "1.0.1"

  def project do
    [
      app: :mixpanel_api_ex,
      version: @version,
      elixir: "~> 1.15",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_deps: :apps_direct,
        plt_add_apps: [:logger],
        flags: [
          "-Werror_handling",
          "-Wextra_return",
          "-Wmissing_return",
          "-Wunknown",
          "-Wunmatched_returns",
          "-Wunderspecs"
        ]
      ],
      test_coverage: [
        summary: [
          threshold: 70
        ]
      ],

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "Mixpanel API",
      docs: [
        extras: ["README.md", "CHANGELOG.md"],
        source_ref: "v#{@version}",
        main: "Mixpanel",
        source_url: "https://github.com/asakura/mixpanel_api_ex"
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
      links: %{"GitHub" => "https://github.com/asakura/mixpanel_api_ex"},
      files: ~w(mix.exs README.md CHANGELOG.md lib)
    ]
  end

  def application(:test) do
    [mod: {Mixpanel, []}, extra_applications: [:logger, :jason]]
  end

  def application(_) do
    [mod: {Mixpanel, []}, extra_applications: [:logger]]
  end

  defp deps do
    [
      {:httpoison, "~> 2.1"},
      {:hackney, "~> 1.20"},
      {:jason, "~> 1.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
