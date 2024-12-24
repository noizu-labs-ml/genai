defmodule GenAI.MixProject do
  use Mix.Project

  def project do
    [
      app: :genai,
      name: "GenAI Wrapper",
      description: description(),
      package: package(),
      version: "0.0.5",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [
        main: "GenAI",
        extras: [
          "README.md",
          "CHANGELOG.md",
          "TODO.md",
          "CONTRIBUTING.md",
          "LICENSE"
        ]
      ],
        dialyzer: [
        plt_file: {:no_warn, "priv/plts/project.plt"}
      ],
      test_coverage: [
        summary: [
          threshold: 40
        ],
        ignore_modules: [
        ]
      ]
    ]
  end

  defp description() do
    "Generative AI Wrapper: access multiple apis through single standardized interface."
  end


  defp package() do
    [
      licenses: ["MIT"],
      links: %{
        project: "https://github.com/noizu-labs-ml/genai",
      },
      files: [
        "mix.exs",
        "lib",
        "README.md",
        "CONTRIBUTING.md",
        "TODO.md",
        "LICENSE",
      ]
    ]
  end


  defp env_applications(), do: env_applications(Mix.env())
  defp env_applications(:dev), do: [:ex_doc]
  defp env_applications(:test), do: [:junit_formatter]
  defp env_applications(_), do: []

  def application do
    [
      mod: {
        GenAI.Application,
        [
        ]
      },
      extra_applications: [:logger, :finch, :jason | env_applications()]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do

    test_deps = [
      {:junit_formatter, "~> 3.3", only: [:test]},
      {:mimic, "~> 1.0.0", only: :test},
    ]

    hex_deps = [
      # Documentation Provider
      {:ex_doc, "~> 0.28.3", only: [:dev, :test], optional: true, runtime: false},

      # Static Analysis: Type Checking
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    ]

    common = [
      # html parser and api client
      {:floki, ">= 0.30.0"},
      {:finch, "~> 0.15"},

      # UUID Library
      {:elixir_uuid, "~> 1.2"},
      #{:shortuuid, "~> 3.0"},


      # JSON/YAML
      {:jason, "~> 1.2"},
      #{:ymlr, "~> 4.0"},
      #{:yaml_elixir, "~> 2.9.0"},
      #{:sweet_xml, "~> 0.7", only: :test}
    ]

    common ++ test_deps ++ hex_deps
  end
end
