defmodule GQLErrorMessage.CommonError.ErrorMessageHook do
  @moduledoc """
  Behaviour for customizing how `ErrorMessage` structs are translated.

  This behaviour provides fine-grained hooks into the
  `GQLErrorMessage.CommonError.ErrorMessageTranslator` pipeline. Instead
  of replacing the entire translator, you can override individual steps:
  classification, message building, and field inference.

  All callbacks are optional. When a callback is not implemented, the
  translator falls back to its built-in default logic.

  ## Callbacks

    * `classify/2` — determines whether an error code produces a
      `ClientError` or `ServerError`. Receives the HTTP status code atom
      and the error details map. Return `:client` or `:server`.

    * `build_message/4` — customizes the error message. Receives the
      original message string, the HTTP status code atom, the error
      details map, and the resolver arguments map. Return the final
      message string.

    * `infer_fields/2` — overrides field inference. Receives the error
      details map and the resolver arguments map. Return a list of
      `{path, value}` tuples where `path` is a list of atoms and
      `value` is the corresponding input value. Return an empty list
      to skip field inference.

  ## Writing a Hook

      defmodule MyApp.ErrorMessageHook do
        @behaviour GQLErrorMessage.CommonError.ErrorMessageHook

        @impl GQLErrorMessage.CommonError.ErrorMessageHook
        def classify(:bad_request, %{severity: :critical}), do: :server
        def classify(code, _details) do
          GQLErrorMessage.CommonError.ErrorMessageTranslator.classify(code)
        end

        @impl GQLErrorMessage.CommonError.ErrorMessageHook
        def build_message(_message, :conflict, %{entity: entity}, _args) do
          "A \#{entity} with that value already exists"
        end
        def build_message(message, _code, _details, _args), do: message
      end

  ## Registering a Hook

  Set the hook module in your application config:

      config :gql_error_message, :error_message_hook, MyApp.ErrorMessageHook

  Or pass the `:error_message_hook` option at call time:

      GQLErrorMessage.translate(error, args, error_message_hook: MyApp.ErrorMessageHook)

  The per-call option overrides the application config.
  """

  @doc """
  Classifies an error code as `:client` or `:server`.

  Receives the HTTP status code atom (e.g. `:bad_request`) and the
  error details map. Return `:client` to produce a `ClientError` or
  `:server` to produce a `ServerError`.
  """
  @callback classify(code :: atom(), details :: map()) :: :client | :server

  @doc """
  Customizes the error message.

  Receives the original message string, the HTTP status code atom,
  the error details map, and the resolver arguments map. Return the
  final message string to use in the GraphQL error struct.
  """
  @callback build_message(
              message :: String.t(),
              code :: atom(),
              details :: map(),
              args :: map()
            ) :: String.t()

  @doc """
  Overrides field inference.

  Receives the error details map and the resolver arguments map.
  Return a list of `{path, value}` tuples where `path` is a list of
  atoms representing the field path and `value` is the corresponding
  input value from the resolver arguments.

  Return an empty list to produce a single error with `field: []`.
  """
  @callback infer_fields(details :: map(), args :: map()) ::
              [{path :: [atom()], value :: term()}]

  @optional_callbacks [classify: 2, build_message: 4, infer_fields: 2]
end
