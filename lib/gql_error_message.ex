defmodule GQLErrorMessage do
  @moduledoc """
  Translates Elixir error terms into GraphQL-compliant error structs.

  When a resolver in an Absinthe schema returns `{:error, reason}`, the
  `reason` can be any Elixir term — an `ErrorMessage` struct, an
  `Ecto.Changeset`, or a custom error type. This module provides a single
  entry point, `translate/3`, that delegates to the configured adapter
  module. The adapter pattern-matches on the error and converts it
  into a list of `GQLErrorMessage.ClientError` or
  `GQLErrorMessage.ServerError` structs.

  A `ClientError` represents an input validation problem that should be
  shown to the end user (for example, "email is invalid"). A `ServerError`
  represents an internal failure that appears in the top-level `errors`
  array of the GraphQL response (for example, "database connection failed").

  ## Getting Started

  ### 1. Add the dependency

  Add `:gql_error_message` to the deps in your `mix.exs`:

      {:gql_error_message, "~> 0.1.0"}

  ### 2. Generate the `:user_error` type

  Run the generator to create an Absinthe types module in your
  application. This module defines the `:user_error` object type with
  two fields: `field` (a list of strings identifying the invalid input
  field) and `message` (a human-readable error description).

      mix gql_error_message.gen.types

  By default the generated module is `<AppName>Web.Schema.Types.UserError`.
  You can override the module name with the `--module` flag:

      mix gql_error_message.gen.types --module MyAppWeb.GraphQL.Types.UserError

  Then import the generated module into your Absinthe schema:

      defmodule MyApp.Schema do
        use Absinthe.Schema

        import_types MyAppWeb.Schema.Types.UserError

        query do
          # ...
        end

        mutation do
          # ...
        end
      end

  ### 3. Add the middleware

  Add `GQLErrorMessage.Absinthe.Middleware` to your schema so that
  resolver errors are automatically translated. The recommended
  approach is to apply the middleware globally by defining the
  `middleware/3` callback in your schema module. Append the middleware
  to the end of the list so it runs after resolution:

      def middleware(middleware, _field, _object) do
        middleware ++ [GQLErrorMessage.Absinthe.Middleware]
      end

  You can also add it per-field after `resolve`:

      field :create_user, :create_user_payload do
        arg :input, non_null(:create_user_input)
        resolve &MyApp.Resolvers.Users.create_user/3
        middleware GQLErrorMessage.Absinthe.Middleware
      end

  ### 4. Add `user_errors` to mutation payloads

  Each mutation payload type must include a `user_errors` field so that
  client errors (input validation errors) can be returned to the caller:

      object :create_user_payload do
        field :user, :user
        field :user_errors, list_of(:user_error)
      end

  ### 5. Return errors from resolvers

  In your resolvers, return `{:error, reason}` where `reason` is an
  `ErrorMessage` struct or an `Ecto.Changeset`. The middleware will
  translate the error and place it in the correct location in the
  GraphQL response automatically.

      defmodule MyApp.Resolvers.Users do
        def create_user(_, %{input: input}, _resolution) do
          case MyApp.Users.create(input) do
            {:ok, user} -> {:ok, %{user: user}}
            {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
            {:error, reason} -> {:error, reason}
          end
        end
      end

  With the above setup, a failed mutation returns client errors inside
  the payload's `user_errors` field, and server errors in the top-level
  `errors` array. A query error always appears in the top-level `errors`
  array because queries do not have a payload object with `user_errors`.

  ## Using the API

  There are three main ways to use this library, depending on how much
  control you need over error translation.

  ### Absinthe middleware (automatic)

  This is the recommended approach for most applications. Add
  `GQLErrorMessage.Absinthe.Middleware` to your schema (as shown in
  Getting Started above) and let it call `translate/3` for you. The
  middleware intercepts every `{:error, reason}` returned by a resolver,
  translates it, and places the resulting `ClientError` and `ServerError`
  structs into the correct location in the GraphQL response. See
  `GQLErrorMessage.Absinthe.Middleware` for details on error placement
  rules for mutations, queries, and subscriptions.

  ### Direct translation

  Call `GQLErrorMessage.translate/3` manually when you are not using
  Absinthe, when you need translated errors outside the middleware
  pipeline, or when you want to inspect the translation result in tests.
  Pass the error term, the resolver arguments map, and an optional
  keyword list of options:

      iex> GQLErrorMessage.translate(ErrorMessage.bad_request("is invalid"), %{})
      [%GQLErrorMessage.ClientError{field: [], message: "is invalid"}]

  ### Hook-based customization

  Use `GQLErrorMessage.CommonError.handle_error/2` inside a resolver to
  attach a per-resolver hook module. The hook module implements the
  `GQLErrorMessage.CommonError.ErrorMessageHook` behaviour and can
  override individual steps of the translation pipeline: classification
  (whether an error is client or server), message building, and field
  inference. This approach lets you customize translation without
  replacing the entire translator. See
  `GQLErrorMessage.CommonError.ErrorMessageHook` for details on
  writing a hook module.

      defmodule MyApp.Resolvers.Users do
        alias GQLErrorMessage.CommonError

        def create_user(_, %{input: input}, _resolution) do
          CommonError.handle_error(MyApp.UserErrorHook, fn ->
            case MyApp.Users.create(input) do
              {:ok, user} -> {:ok, %{user: user}}
              {:error, error} -> {:error, error}
            end
          end)
        end
      end

  ## How Translation Works

  `translate/3` delegates to the configured adapter module. The
  adapter pattern-matches on the error term and converts it into a
  list of error structs. If the adapter does not recognize the error
  type, it raises.

  The second argument, `args`, is the resolver arguments map from the
  Absinthe resolution struct (`resolution.arguments`). Adapters use
  this map to infer which input fields caused the error. For mutations,
  this map typically has the shape `%{input: %{email: "...", name: "..."}}`.
  For queries, the keys are the field arguments directly.

  The third argument, `opts`, is an optional keyword list. The
  `:adapter` option overrides the configured adapter module for this
  call. The `:error_message_hook` option overrides the hook used
  inside `ErrorMessageTranslator` (see
  `GQLErrorMessage.CommonError.ErrorMessageHook`).

  ## Default Adapter

  The default adapter is `GQLErrorMessage.CommonError`, which
  handles two error types out of the box:

    * `%ErrorMessage{}` structs (from the `:error_message` hex package)
      are delegated to `GQLErrorMessage.CommonError.ErrorMessageTranslator`, which
      classifies errors as client or server based on the HTTP status code,
      performs field inference from `error.details`, and supports message
      templates.

    * `%Ecto.Changeset{}` structs are delegated to
      `GQLErrorMessage.CommonError.ChangesetTranslator`, which traverses changeset
      validation errors and produces one `ClientError` per field/message
      pair.

  ## Configuration

  You can replace the default adapter by setting the `:translator`
  key in your application config:

      config :gql_error_message, :translator, MyApp.CustomTranslator

  Or pass the `:adapter` option at call time:

      GQLErrorMessage.translate(error, args, adapter: MyApp.CustomTranslator)

  The custom adapter must implement the `GQLErrorMessage.Translator`
  behaviour. See `GQLErrorMessage.Translator` for details on writing a
  custom adapter.

  ## Examples

      iex> GQLErrorMessage.translate(ErrorMessage.bad_request("is invalid"), %{})
      [%GQLErrorMessage.ClientError{field: [], message: "is invalid"}]

  """

  alias GQLErrorMessage.{ClientError, Config, ServerError}

  @type gql_error :: ClientError.t() | ServerError.t()

  @doc """
  Translates an error term into a list of GraphQL error structs.

  Delegates to the configured adapter module. The adapter
  pattern-matches on the error and returns a list of
  `GQLErrorMessage.ClientError` and/or `GQLErrorMessage.ServerError`
  structs.

  The `error` argument is the value from the `{:error, reason}` tuple
  that a resolver returns. It can be any Elixir term — the adapter
  module decides which types it supports. If the adapter does not
  recognize the error type, it raises.

  The `args` argument is the resolver arguments map from the
  Absinthe resolution struct (`resolution.arguments`). Adapters use
  this map to perform field inference, which means they figure out which
  specific input field caused the error and attach that path to the error
  struct.

  The `opts` argument is an optional keyword list that supports:

    * `:adapter` — overrides the configured adapter module for this
      call. Defaults to the value of `config :gql_error_message, :translator`.

    * `:error_message_hook` — a module implementing
      `GQLErrorMessage.CommonError.ErrorMessageHook` that customizes
      classification, message building, and field inference inside
      `ErrorMessageTranslator`. Defaults to the value of
      `config :gql_error_message, :error_message_hook` (nil if not set).

  ## Examples

  Translating an `ErrorMessage` struct without resolver arguments:

      iex> GQLErrorMessage.translate(ErrorMessage.bad_request("is invalid"), %{})
      [%GQLErrorMessage.ClientError{field: [], message: "is invalid"}]

  Translating an `ErrorMessage` struct with resolver arguments for field
  inference. The `:input` key in `details` tells the adapter which
  fields to look for in the resolver arguments:

      iex> error = ErrorMessage.bad_request("is invalid", %{input: %{email: nil}})
      ...> GQLErrorMessage.translate(error, %{input: %{email: "bad@"}})
      [%GQLErrorMessage.ClientError{field: [:email], message: "is invalid"}]

  """
  @spec translate(term(), map(), keyword()) :: [gql_error()]
  def translate(error, args, opts \\ []) when is_map(args) and is_list(opts) do
    adapter = Keyword.get(opts, :adapter, Config.translator())
    adapter.translate(error, args, opts)
  end
end
