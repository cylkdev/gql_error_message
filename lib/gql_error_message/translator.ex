defmodule GQLErrorMessage.Translator do
  @moduledoc """
  Behaviour for translating error terms into GraphQL error structs.

  A translator is a single module responsible for converting any Elixir
  error term into a list of `GQLErrorMessage.ClientError` or
  `GQLErrorMessage.ServerError` structs. The main module
  `GQLErrorMessage.translate/3` delegates directly to the configured
  translator module.

  The default translator is `GQLErrorMessage.CommonError`, which
  pattern-matches on the error type and delegates to the appropriate
  built-in translator (`GQLErrorMessage.CommonError.ErrorMessageTranslator` for
  `ErrorMessage` structs, `GQLErrorMessage.CommonError.ChangesetTranslator` for
  `Ecto.Changeset` structs).

  ## Writing a Custom Translator

  To add support for custom error types, create a module that implements
  this behaviour. Pattern-match on your custom error types and delegate
  to the built-in translators for standard types. The translator must
  handle every error type it receives — if it encounters an unrecognized
  type, it must raise:

      defmodule MyApp.CustomTranslator do
        @behaviour GQLErrorMessage.Translator

        alias GQLErrorMessage.Translator

        @impl GQLErrorMessage.Translator
        def translate(%MyApp.DomainError{} = error, _args, _opts) do
          [%GQLErrorMessage.ClientError{field: [], message: error.message}]
        end

        def translate(%Ecto.Changeset{} = changeset, args, _opts) do
          CommonError.ChangesetTranslator.translate(changeset, args)
        end

        def translate(%ErrorMessage{} = error, args, opts) do
          CommonError.ErrorMessageTranslator.translate(error, args, opts)
        end
      end

  The `translate/3` callback receives three arguments:

    1. The error term — the value from the `{:error, reason}` tuple that
       a resolver returned.

    2. The resolver arguments map — the `resolution.arguments` from the
       Absinthe resolution struct. For mutations this map typically has
       the shape `%{input: %{email: "...", name: "..."}}`. For queries
       the keys are the field arguments directly. Translators can use
       this map to perform field inference (figuring out which input
       field caused the error).

    3. A keyword list of options forwarded from
       `GQLErrorMessage.translate/3`. This allows the adapter to pass
       options such as `:error_message_hook` to sub-translators.

  The callback must return a list of `GQLErrorMessage.ClientError`
  and/or `GQLErrorMessage.ServerError` structs. If the translator does
  not recognize the error type, it must raise a
  `FunctionClauseError` (by not having a matching clause) or raise
  explicitly with a descriptive message.

  ## Registering a Custom Translator

  Set your translator module in your application config:

      config :gql_error_message, :translator, MyApp.CustomTranslator

  If you do not set this config, `GQLErrorMessage.CommonError` is
  used.
  """

  alias GQLErrorMessage.{ClientError, ServerError}

  @type gql_error :: ClientError.t() | ServerError.t()

  @doc """
  Translates an error term into a list of GraphQL error structs.

  The `error` argument is the value from the `{:error, reason}` tuple
  that a resolver returned. It can be any Elixir term.

  The `args` argument is the resolver arguments map from the Absinthe
  resolution struct (`resolution.arguments`). For mutations the
  top-level key is typically `:input` (for example,
  `%{input: %{email: "test@test.com"}}`). For queries the keys are the
  field arguments directly (for example, `%{id: "123"}`).

  Returns a list of `GQLErrorMessage.ClientError` and/or
  `GQLErrorMessage.ServerError` structs.

  Raises if the translator does not recognize the error type.
  """
  @callback translate(error :: term(), args :: map(), opts :: keyword()) :: [gql_error()]
end
