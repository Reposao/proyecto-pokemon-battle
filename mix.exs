defmodule PokemonBattle.MixProject do
  use Mix.Project

  def project do
    [
      app: :pokemon_battle,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PokemonBattle.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
  [
    {:jason, "~> 1.4"}
  ]
  end
end

