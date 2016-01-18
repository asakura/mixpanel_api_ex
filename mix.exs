defmodule Mixpanel.Mixfile do
  use Mix.Project

  @version "0.8.1"

  def project do
    [app: :mixpanel_api_ex,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,

     # Hex
     description: description,
     package: package,

     # Docs
     name: "Mixpanel API",
     docs: [extras: ["README.md", "CHANGELOG.md"],
            source_ref: "v#{@version}", main: "Mixpanel",
            source_url: "https://github.com/asakura/mixpanel_api_ex"]]
  end

  def description do
    "Elixir client for the Mixpanel API."
  end

  def package do
    [maintainers: ["Mikalai Seva"],
     licenses: ["The MIT License"],
     links: %{"GitHub" => "https://github.com/asakura/mixpanel_api_ex"},
     files: ~w(mix.exs README.md CHANGELOG.md lib)]
  end

  def application do
    [mod: {Mixpanel, []},
     applications: [:logger, :httpoison]]
  end

  defp deps do
    [{:httpoison, "~> 0.8.0"},
     {:poison, "~> 1.5.2"},
     {:credo, "~> 0.2", only: :dev},
     {:dogma, "~> 0.0", only: :dev},
     {:dialyxir, "~> 0.3", only: :dev},
     {:mock, "~> 0.1.1", only: :test},
     {:ex_doc, "~> 0.10", only: :docs},
     {:earmark, "~> 0.1", only: :docs},
     {:inch_ex, ">= 0.0.0", only: :docs}]
  end
end
