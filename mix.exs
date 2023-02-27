defmodule Vials.MixProject do
  use Mix.Project

  @version "0.1.0"
  @scm_url "https://github.com/sodapopcan/vials"

  def project do
    [
      app: :vials,
      version: @version,
      version: "0.1.0",
      elixir: "~> 1.14",
      package: package(),
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Vials],
      deps: deps(),
      source_url: @scm_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: "https://github.com/sodapopcan/vials",
      description: "Wrappers for mix generators"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/tasks"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mix]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sourceror, "~> 0.12"}
    ]
  end

  defp package do
    [
      maintainers: ["Andrew Haust"],
      licenses: ["MIT"],
      links: %{"GitHub" => @scm_url}
    ]
  end
end
