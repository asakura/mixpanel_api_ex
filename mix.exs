defmodule Mixpanel.Mixfile do
  use Mix.Project

  @version "1.1.1"

  def project do
    [
      app: :mixpanel_api_ex,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: compilers(Mix.env()),
      unused: unused(),
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: preferred_cli_env(),
      dialyzer: [
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_deps: :apps_direct,
        plt_add_apps: [:logger, :inets],
        flags: [
          "-Werror_handling",
          "-Wextra_return",
          "-Wmissing_return",
          "-Wunknown",
          "-Wunmatched_returns",
          "-Wunderspecs"
        ]
      ],
      propcheck: [counter_examples: "propcheck_counter_examples"],
      test_paths: test_paths(Mix.env()),
      test_coverage: [
        summary: [
          threshold: 80
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

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(:property), do: ["property/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:property), do: ["property"]
  defp test_paths(_), do: ["test"]

  def package do
    [
      maintainers: ["Mikalai Seva"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/asakura/mixpanel_api_ex"},
      files: ~w(mix.exs README.md CHANGELOG.md lib)
    ]
  end

  def application() do
    [mod: {Mixpanel, []}, extra_applications: [:logger]]
  end

  defp compilers(:dev) do
    [:unused] ++ Mix.compilers()
  end

  defp compilers(_), do: Mix.compilers()

  defp deps do
    [
      {:bandit, "~> 1.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:gradient, github: "esl/gradient", ref: "33e13fb", only: [:dev], runtime: false},
      {:gradient_macros, github: "esl/gradient_macros", ref: "3bce214", runtime: false},
      {:hackney, "~> 1.20", only: [:test, :dev]},
      {:jason, "~> 1.4"},
      {:machete, "~> 0.2", only: :test},
      {:mix_unused, "~> 0.4.1"},
      {:mox, "~> 1.1", only: :test},
      {:propcheck, "~> 1.4", only: [:property, :dev]},
      {:telemetry, "~> 0.4 or ~> 1.0"}
    ]
  end

  defp preferred_cli_env do
    [
      c: :dev,
      t: :test,
      ti: :test,
      p: :property,
      "test.property": :property
    ]
  end

  defp aliases() do
    [
      c: "compile",
      t: "test --no-start",
      p: &run_property_tests/1,
      d: "dialyzer",
      g: "gradient",
      test: "test --no-start",
      "test.property": &run_property_tests/1
    ]
  end

  defp unused() do
    [
      ignore: [
        {:_, :child_spec, :_},
        {:_, :start_link, :_}
      ]
    ]
  end

  defp run_property_tests(args) do
    env = Mix.env()
    args = if IO.ANSI.enabled?(), do: ["--color" | args], else: ["--no-color" | args]
    IO.puts("Running tests with `MIX_ENV=#{env}`")

    {_, res} =
      System.cmd("mix", ["test" | args],
        into: IO.binstream(:stdio, :line),
        env: [{"MIX_ENV", to_string(env)}]
      )

    if res > 0 do
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end
  end
end
