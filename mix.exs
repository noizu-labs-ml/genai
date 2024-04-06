defmodule GenAI.MixProject do
  use Mix.Project

  def project do
    [
      app: :genai,
      name: "Noizu Labs, GenAI Wrapper",
      description: description(),
      package: package(),
      version: "0.0.2",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "GenAI",
        extras: [
          "README.md",
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
        noizu_labs: "https://github.com/noizu-labs",
        noizu_labs_machine_learning: "https://github.com/noizu-labs-ml",
        noizu_labs_scaffolding: "https://github.com/noizu-labs-scaffolding",
        developer_github: "https://github.com/noizu"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    dev_apps = if Mix.env() in [:dev] do
      [:ex_doc]
    else
      []
    end

    test_apps = if Mix.env() in [:test] do
      [:junit_formatter]
    else
      []
    end

    [
      mod: {
        GenAI.Application,
        [
        ]
      },
      extra_applications: [:logger, :finch, :jason] ++ dev_apps ++ test_apps
    ]
  end


  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:floki, ">= 0.30.0"},
      {:elixir_uuid, "~> 1.2"},
      {:shortuuid, "~> 3.0"},
      {:junit_formatter, "~> 3.3", only: [:test]},
      {:ex_doc, "~> 0.28.3", only: [:dev, :test], optional: true, runtime: false}, # Documentation Provider
      {:finch, "~> 0.15"},
      {:jason, "~> 1.2"},
      {:ymlr, "~> 4.0"},
      {:yaml_elixir, "~> 2.9.0"},
      {:mimic, "~> 1.0.0", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sweet_xml, "~> 0.7", only: :test}
    ]
  end
end
