defmodule GQLErrorMessage.MixProject do
  use Mix.Project

  def project do
    [
      app: :gql_error_message,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_options, ">= 1.0.0"},

      # optional
      {:error_message, ">= 0.1.0", optional: true},
      {:absinthe, ">= 1.0.0", optional: true},
      {:ecto, ">= 1.0.0", optional: true}
    ]
  end
end
