defmodule GenAI.MixProject do
  use Mix.Project

  def project do
    [
      app: :genai,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {
        GenAI.Application,
        [
        ]
      },
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:junit_formatter, "~> 3.3", only: [:test]},
      {:ex_doc, "~> 0.28.3", only: [:dev, :test], optional: true, runtime: false}, # Documentation Provider
      {:finch, "~> 0.15"},
      {:jason, "~> 1.2"},
      {:mimic, "~> 1.0.0", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sweet_xml, "~> 0.7", only: :test}
    ]
  end
end
