defmodule GQLErrorMessage.CommonError do
  @moduledoc """
  The default translator module for dispatching errors to built-in translators.

  This module implements the `GQLErrorMessage.Translator` behaviour and serves
  as the default error dispatcher. It pattern-matches on the incoming error
  term and delegates to the appropriate built-in translator:

    * `%Ecto.Changeset{}` errors are delegated to
      `GQLErrorMessage.CommonError.ChangesetTranslator`

    * `%ErrorMessage{}` errors are delegated to
      `GQLErrorMessage.CommonError.ErrorMessageTranslator`

    * Plain maps with a `:message` key are recognized as
      Absinthe-normalized errors. A map with `:message` and
      `:extensions` becomes a `GQLErrorMessage.ServerError`. A map
      with `:message` and `:field` becomes a
      `GQLErrorMessage.ClientError`. A map with only `:message`
      becomes a `GQLErrorMessage.ServerError` with empty extensions.
      This handles the case where Absinthe 1.9+ normalizes error
      structs into plain maps during nested field resolution.

  If the error does not match any known type, a `RuntimeError` is
  raised. This ensures that unhandled error types are caught during
  development rather than silently ignored.

  This module is used automatically when no custom translator is configured.
  To use a custom translator, set the `:translator` key in your application
  config:

      config :gql_error_message, :translator, MyApp.CustomTranslator

  A custom translator module must implement the `GQLErrorMessage.Translator`
  behaviour. It can delegate to the built-in translators for standard error
  types and add handling for application-specific error types:

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

  ## Examples

      iex> alias GQLErrorMessage.CommonError
      ...> error = ErrorMessage.bad_request("is invalid")
      ...> CommonError.translate(error, %{}, [])
      [%GQLErrorMessage.ClientError{field: [], message: "is invalid"}]

  """

  @behaviour GQLErrorMessage.Translator

  alias GQLErrorMessage.{
    ClientError,
    ServerError
  }

  alias GQLErrorMessage.CommonError.{
    ChangesetTranslator,
    ErrorContext,
    ErrorMessageTranslator
  }

  @doc """
  Wraps the result of a resolver callback with an `ErrorContext`.

  When the callback returns `{:ok, value}`, the result passes through
  unchanged. When it returns `{:error, reason}`, the error is wrapped
  in an `ErrorContext` struct that carries the given hook module.

  The hook module should implement the
  `GQLErrorMessage.CommonError.ErrorMessageHook` behaviour.
  When the wrapped error is later translated, the hook module's
  callbacks are used to customize classification, message building,
  and field inference.

  ## Examples

      defmodule MyApp.Resolvers.Users do
        @behaviour GQLErrorMessage.CommonError.ErrorMessageHook

        alias GQLErrorMessage.CommonError

        def create_user(_, %{input: input}, _resolution) do
          CommonError.handle_error(__MODULE__, fn ->
            case MyApp.Users.create(input) do
              {:ok, user} -> {:ok, %{user: user}}
              {:error, error} -> {:error, error}
            end
          end)
        end

        @impl GQLErrorMessage.CommonError.ErrorMessageHook
        def classify(:bad_request, %{severity: :critical}), do: :server
        def classify(code, _details) do
          GQLErrorMessage.CommonError.ErrorMessageTranslator.classify(code)
        end
      end

  """
  @spec handle_error(module(), (-> {:ok, term()} | {:error, term()})) ::
          {:ok, term()} | {:error, ErrorContext.t()}
  def handle_error(hook, callback) when is_atom(hook) and is_function(callback, 0) do
    case callback.() do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, %ErrorContext{value: reason, hook_module: hook}}
    end
  end

  @impl GQLErrorMessage.Translator

  @spec translate(term(), map(), keyword()) :: [GQLErrorMessage.gql_error()]
  def translate(%ClientError{} = error, _args, _opts) do
    [error]
  end

  def translate(%ServerError{} = error, _args, _opts) do
    [error]
  end

  def translate(%ErrorContext{value: value, hook_module: hook}, args, opts) do
    opts = Keyword.put(opts, :error_message_hook, hook)
    translate(value, args, opts)
  end

  def translate(%Ecto.Changeset{} = changeset, args, _opts) do
    ChangesetTranslator.translate(changeset, args)
  end

  def translate(%ErrorMessage{} = error, args, opts) do
    ErrorMessageTranslator.translate(error, args, opts)
  end

  def translate(%{message: message, extensions: extensions}, _args, _opts)
      when is_binary(message) and is_map(extensions) do
    [ServerError.new(message, extensions)]
  end

  def translate(%{message: message, field: field}, _args, _opts)
      when is_binary(message) and is_list(field) do
    [ClientError.new(field, message)]
  end

  def translate(%{message: message}, _args, _opts)
      when is_binary(message) do
    [ServerError.new(message)]
  end

  def translate(error, _args, _opts) do
    raise "Unsupported error type: #{inspect(error)}"
  end
end
