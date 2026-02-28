defmodule GQLErrorMessage.MixProject do
  use Mix.Project

  @version "0.1.0"
  @canonical_url "https://hexdocs.pm/gql_error_message"
  @source_url "https://github.com/cylkdev/gql_error_message"

  def project do
    [
      app: :gql_error_message,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      deps: deps(),
      docs: docs(),
      description: "A standardized API for translating Elixir errors into GraphQL-compliant error messages.",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url},
        files: ~w(lib priv .formatter.exs mix.exs README.md CHANGELOG.md LICENSE)
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

  defp deps do
    [
      # Core dependencies
      {:error_message, ">= 0.1.0"},
      {:absinthe, ">= 1.0.0", optional: true},
      {:absinthe_relay, "~> 1.5", optional: true},
      {:ecto, ">= 1.0.0", optional: true},

      # Documentation
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},

      # Code quality and static analysis (linting, style checks, and type checking)
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:blitz_credo_checks, "~> 0.1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Testing and coverage (tools used only when running the test suite)
      {:excoveralls, "~> 0.13", only: :test},

      # Debugging and runtime introspection (tools for inspecting running systems)
      {:rexbug, "~> 1.0", only: :dev},
      {:observer_cli, "~> 1.8", only: :dev},
      {:etop, "~> 0.7", only: :dev}
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
        Translators: [
          GQLErrorMessage.Translator,
          GQLErrorMessage.CommonError,
          GQLErrorMessage.CommonError.ErrorMessageTranslator,
          GQLErrorMessage.CommonError.ChangesetTranslator,
          GQLErrorMessage.CommonError.ErrorMessageHook,
          GQLErrorMessage.CommonError.ErrorContext
        ],
        "Absinthe API": [
          GQLErrorMessage.Absinthe.Middleware
        ],
        Generator: [
          GQLErrorMessage.Generator,
          GQLErrorMessage.Generator.TemplateBuilder,
          GQLErrorMessage.Generator.FileWriter,
          GQLErrorMessage.Generator.SchemaInjector
        ],
        "Mix Tasks": [
          Mix.Tasks.GqlErrorMessage.Gen.Types
        ],
        Configuration: [
          GQLErrorMessage.Config
        ],
        Utilities: [
          GQLErrorMessage.Serializer
        ]
      ]
    ]
  end
end
