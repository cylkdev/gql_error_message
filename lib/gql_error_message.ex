defmodule GQLErrorMessage do
  @moduledoc """
  GQLErrorMessage provides a transparent, standardized API for translating
  Elixir error terms into GraphQL-compliant error messages.

  ## Installation

  The package can be installed by adding `gql_error_message` to your list of
  dependencies in `mix.exs`:

      def deps do
        [
          {:gql_error_message, "~> 1.0"}
        ]
      end

  After you are done, run `mix deps.get` in your shell to fetch the dependencies.

  ## Getting Started

  GQLErrorMessage is split into 4 main components:

    * `GQLErrorMessage.Adapter` - Adapters contain the logic for how to
      translate different error terms.

    * `GQLErrorMessage.Repo` - Repositories are responsible for storing
      and retrieving error specifications.

    * `GQLErrorMessage.Spec` - Specifications are blueprints that define the
      properties of an error.

    * `GQLErrorMessage.ClientError` & `GQLErrorMessage.ServerError` - These are the
      standardized structs that represent the final, translated errors.

  In summary:

    * **Adapter** - How to translate the error.
    * **Repo** - Where the error specs are.
    * **Spec** - What the error spec is.
    * **ClientError & ServerError** - What the translated error is.

  For integration with the Absinthe GraphQL library, see
  `GQLErrorMessage.Absinthe`.

  If you want to quickly get started, please see the "Quick Start" guide below.

  ## Quick Start: Absinthe Integration

  The most common way to use this library is with the provided Absinthe
  middleware. Simply add it to your field after the resolver:

      # in your schema.ex
      field :create_user, :user_payload do
        arg :input, non_null(:user_input)
        resolve &Accounts.create_user/3

        middleware GQLErrorMessage.Absinthe.Middleware
      end

  Now, if your resolver returns an error tuple like `{:error, changeset}`,
  the middleware will automatically translate it.

  ## Under the Hood: The Translation Pipeline

  The middleware shown above is the simplest way to use the library, as it
  handles the translation process automatically. The following sections break
  down each component of that pipeline, explaining how the library works and
  how you can customize its behavior.

  ### Adapters

  An `Adapter` is a module that contains the logic for how to translate
  different error terms. The library includes `GQLErrorMessage.Translation`
  as the default adapter, which can handle `Ecto.Changeset` and `ErrorMessage`
  structs.

  ### Repositories

  A `Repo` is a module responsible for storing and retrieving `Spec`s. The
  library includes `GQLErrorMessage.DefaultRepo`, which is pre-populated
  with common error specifications.

  ### Specifications

  A `Spec` is a struct that acts as a blueprint for an error. It defines:
    - The `operation` (`:query`, `:mutation`, etc.)
    - The `kind` (`:client_error` or `:server_error`)
    - The `code` (e.g., `:bad_request`)
    - A default `message` and `extensions` map.

  ### Error Structs

  The final output of the translation process is one of two structs:

    * `ClientError` - Represents a user-facing error caused by invalid input.
    * `ServerError` - Represents an internal server issue.

  ## Configuration

  You can customize the library's behavior in your `config/config.exs` file:

      config :gql_error_message,
        adapter: MyApp.CustomAdapter,
        repo: MyApp.CustomRepo,
        serializer: MyApp.CustomSerializer,
        fallback_error: %{message: "An unexpected error occurred."}
  """
  alias GQLErrorMessage.{
    Adapter,
    ClientError,
    Config,
    Spec,
    ServerError
  }

  @logger_prefix "GQLErrorMessage"

  @operations [:mutation, :query, :subscription]

  @doc """
  Translates an error map into a list of `ClientError` or `ServerError` structs.

  ## Options

    * `repo` - The repository to use for looking up error specs. Defaults to
      `GQLErrorMessage.DefaultRepo`.
    * `fallback_error` - The fallback `GQLErrorMessage.ServerError` struct to
      use when no spec is found.

  ## Examples

      iex> operation = :query
      ...> error = %ErrorMessage{code: :bad_request, message: "invalid request", details: %{params: %{id: 1}}}
      ...> input = %{id: 1}
      ...> GQLErrorMessage.translate_error(operation, error, input)
      [%GQLErrorMessage.ClientError{field: [:id], message: "invalid request"}]

      iex> operation = :query
      ...> error = %ErrorMessage{code: :internal_server_error, message: "internal server error", details: %{params: %{users: %{id: [1, 2, 3]}}}}
      ...> input = %{name: "alice", users: %{id: [1, 2, 3]}}
      ...> GQLErrorMessage.translate_error(operation, error, input)
      [%GQLErrorMessage.ServerError{message: "internal server error", extensions: %{}}]
  """
  @spec translate_error(
          op :: atom(),
          error :: map(),
          input :: map()
        ) :: list()
  @spec translate_error(
          op :: atom(),
          error :: map(),
          input :: map(),
          opts :: keyword()
        ) :: list()
  def translate_error(op, error, input, opts \\ []) when op in @operations do
    adapter = opts[:adapter] || Config.adapter() || GQLErrorMessage.Translation
    repo = opts[:repo] || Config.repo() || GQLErrorMessage.DefaultRepo

    case Adapter.get(adapter, repo, op, error) do
      %Spec{} = spec ->
        translate(adapter, error, input, spec)

      term ->
        raise "Adapter #{inspect(adapter)} did not return a spec, got: #{inspect(term)}"
    end
  end

  defp translate(adapter, error, input, %Spec{kind: :client_error} = spec) do
    adapter
    |> Adapter.translate_error(error, input, spec)
    |> List.wrap()
    |> Enum.map(fn
      %ClientError{} = client_error -> client_error
      term -> raise "Expected a `GQLErrorMessage.ClientError` struct, got: #{inspect(term)}"
    end)
    |> then(fn
      [] ->
        GQLErrorMessage.Logger.debug(
          @logger_prefix,
          """
          Adapter #{inspect(adapter)} did not return any errors.

          error:
          #{inspect(error)}

          input:
          #{inspect(input)}

          spec:
          #{inspect(spec)}
          """
        )

        []

      results ->
        results
    end)
  end

  defp translate(adapter, error, input, %Spec{kind: :server_error} = spec) do
    adapter
    |> Adapter.translate_error(error, input, spec)
    |> List.wrap()
    |> Enum.map(fn
      %ServerError{} = server_error -> server_error
      term -> raise "Expected a `GQLErrorMessage.ServerError` struct, got: #{inspect(term)}"
    end)
    |> then(fn
      [] ->
        GQLErrorMessage.Logger.debug(
          @logger_prefix,
          """
          Adapter #{inspect(adapter)} did not return any errors.

          error:
          #{inspect(error)}

          input:
          #{inspect(input)}

          spec:
          #{inspect(spec)}
          """
        )

        []

      results ->
        results
    end)
  end
end
