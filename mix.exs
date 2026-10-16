defmodule GenAI.MixProject do
  use Mix.Project

  def project do
    [
      app: :genai,
      name: "Noizu Labs, GenAI Wrapper",
      description: description(),
      package: package(),
      version: "0.5.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      # Worktrees use absolute cache symlinks. Let Mix calculate asset links
      # from the physical cache paths, rather than the deeper worktree alias.
      deps_path: cache_path("deps"),
      build_path: cache_path("_build"),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [
        main: "readme",
        source_url: "https://github.com/noizu-labs-ml/genai",
        extras: [
          "README.md",
          "CHANGELOG.md",
          "TODO.md",
          "CONTRIBUTING.md",
          "LICENSE",
          "docs/classifier-providers.md",
          "docs/dashscope-native.md",
          "docs/fork-threads.md"
        ]
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/project.plt"}
      ],
      test_coverage: [
        summary: [
          threshold: 40
        ],
        ignore_modules: []
      ]
    ]
  end

  defp cache_path(name) do
    case File.read_link(Path.join(__DIR__, name)) do
      {:ok, target} -> Path.expand(target, __DIR__)
      _ -> name
    end
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
      },
      files: [
        "lib",
        "docs",
        "examples",
        "BOOK.md",
        "CONTRIBUTING.md",
        "LICENSE",
        "mix.exs",
        "README.md",
        "TODO.md"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    dev_apps =
      if Mix.env() in [:dev] do
        [:ex_doc]
      else
        []
      end

    test_apps =
      if Mix.env() in [:test] do
        [:junit_formatter]
      else
        []
      end

    [
      mod: {
        GenAI.Application,
        []
      },
      extra_applications: [:logger, :finch, :jason] ++ dev_apps ++ test_apps
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Core 0.4.0 is co-developed and not yet published. Normal source checkouts
  # use this immutable merged commit; GENAI_CORE_PATH remains a local/CI override.
  # Switch to the released Hex constraint before publishing this GenAI version.
  defp genai_core_dep do
    case System.get_env("GENAI_CORE_PATH") do
      nil ->
        {:genai_core, "~> 0.4.0",
         git: "https://github.com/noizu-labs-ml/genai-core.git",
         ref: "8e311fb18d14e72d32570ae4677bdb52b870f232",
         override: true}

      path ->
        {:genai_core, path: path, override: true}
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      genai_core_dep(),
      # {:genai_core, github: "noizu-labs-ml/genai-core", branch: "develop"},
      {:floki, ">= 0.30.0"},
      {:elixir_uuid, "~> 1.2"},
      {:shortuuid, "~> 4.0"},
      {:junit_formatter, "~> 3.3", only: [:test]},
      # Documentation Provider
      {:ex_doc, "~> 0.40", only: [:dev, :test], optional: true, runtime: false},
      {:finch, "~> 0.15"},
      {:jason, "~> 1.2"},
      {:ymlr, "~> 5.0"},
      {:yaml_elixir, "~> 2.9"},
      {:mimic, "~> 2.3", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sweet_xml, "~> 0.7", only: :test},
      {:noizu_mcp, "~> 0.5.0", optional: true}
    ] ++ local_classifier_dep()
  end

  # Native compilation is an explicit source-integration opt-in. Published
  # GenAI consumers can instead install ExLLama in their own applications.
  defp local_classifier_dep do
    case System.get_env("GENAI_EX_LLAMA_PATH") do
      nil -> []
      path -> [{:ex_llama, path: path, optional: true, override: true}]
    end
  end
end
