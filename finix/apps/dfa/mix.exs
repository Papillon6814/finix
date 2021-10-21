defmodule Dfa.MixProject do
  use Mix.Project

  def project do
    [
      app: :dfm,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      description: "Finite state machine",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Papillon6814"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/Papillon6814/finix"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:ex_doc, "~> 0.22.0", only: :dev, runtime: false},
      {:redix, "~> 1.1"}
    ]
  end
end
