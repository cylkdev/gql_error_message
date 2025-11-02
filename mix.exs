defmodule GQLErrorMessage.MixProject do
  use Mix.Project

  @version "0.1.0"
  @canonical_url "https://hexdocs.pm/gql_error_message"
  @source_url "https://github.com/cylkdev/gql_error_message"

  def project do
    [
      app: :gql_error_message,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description:
        "A standardized API for translating Elixir errors into GraphQL-compliant error messages.",
      package: [
        licenses: ["MIT License"],
        links: %{"GitHub" => @source_url},
        files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE)
      ]
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:nimble_options, ">= 1.0.0"},

      # optional
      {:error_message, ">= 0.1.0", optional: true},
      {:absinthe, ">= 1.0.0", optional: true},
      {:ecto, ">= 1.0.0", optional: true}
    ]
  end

  def docs do
    [
      main: "GQLErrorMessage",
      canonical: @canonical_url,
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md"],
      groups_for_modules: [
        "Core API": [
          GQLErrorMessage
        ],
        Errors: [
          GQLErrorMessage.ClientError,
          GQLErrorMessage.ServerError
        ],
        "Translation Pipeline": [
          GQLErrorMessage.Adapter,
          GQLErrorMessage.Spec,
          GQLErrorMessage.Repo,
          GQLErrorMessage.DefaultRepo,
          GQLErrorMessage.Translation,
          GQLErrorMessage.Translation.ChangesetTranslation,
          GQLErrorMessage.Translation.ErrorMessageTranslation
        ],
        "Absinthe API": [
          GQLErrorMessage.Absinthe,
          GQLErrorMessage.Absinthe.Middleware,
          GQLErrorMessage.Absinthe.Type
        ],
        Utilities: [
          GQLErrorMessage.Serializer
        ]
      ]
    ]
  end
end
