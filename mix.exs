defmodule GQLErrorMessage.MixProject do
  use Mix.Project

  def project do
    [
      app: :gql_error_message,
      version: "0.1.0",
      elixir: "~> 1.18",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:error_message, "~> 0.3.3", optional: true}
    ]
  end
end
