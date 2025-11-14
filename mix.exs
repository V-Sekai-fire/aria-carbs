# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_carbs,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir wrapper for CARBS (Cost-Aware pareto-Region Bayesian Search) using pythonx",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaCarbs.Application, []}
    ]
  end

  defp deps do
    [
      {:pythonx, "~> 0.4.0"},
      {:jason, "~> 1.4"},
      {:ecto_sqlite3, "~> 0.22.0"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["K. S. Ernest (iFire) Lee"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/V-Sekai-fire/aria-carbs"}
    ]
  end
end

