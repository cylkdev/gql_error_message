defmodule GQLErrorMessage.CommonError.ErrorContext do
  @moduledoc """
  Wrapper struct that pairs an error value with an error message hook module.

  When a resolver uses `GQLErrorMessage.CommonError.handle_error/2`
  to wrap its callback, any `{:error, reason}` return value is automatically
  wrapped in an `ErrorContext` struct. The struct carries two pieces of
  information: the original error value and the hook module that should
  customize how that error is translated into GraphQL error structs.

  You do not create `ErrorContext` structs directly. They are produced by
  `GQLErrorMessage.CommonError.handle_error/2` and consumed by
  the `CommonError` translator. When the translator encounters an
  `ErrorContext` in the error
  position, it extracts the hook module, places it into the translation
  options under the `:hook_module` key, and re-translates the inner
  error value. This causes the hook module's callbacks (defined in
  `GQLErrorMessage.CommonError.ErrorMessageHook`) to be invoked
  during translation, allowing per-resolver customization of classification,
  message building, and field inference.

  ## Fields

    * `:value` — the original error term from the `{:error, reason}` tuple
      that the resolver callback returned. This can be any Elixir term that
      the translator supports, such as an `ErrorMessage` struct or an
      `Ecto.Changeset`.

    * `:hook_module` — the module that implements the
      `GQLErrorMessage.CommonError.ErrorMessageHook` behaviour.
      This module's callbacks are invoked during translation to override
      the default classification, message building, and field inference
      logic.

  Both fields are required. Attempting to create an `ErrorContext` struct
  without either field raises an `ArgumentError`.

  ## How It Flows Through the System

    1. A resolver wraps its callback with
       `CommonError.handle_error(MyHook, fn -> ... end)`.

    2. If the callback returns `{:error, reason}`, `handle_error/2`
       produces
       `{:error, %ErrorContext{value: reason, hook_module: MyHook}}`.

    3. Absinthe places the `ErrorContext` into the resolution's errors
       list.

    4. `GQLErrorMessage.Absinthe.Middleware` calls
       `GQLErrorMessage.translate/3` with the `ErrorContext` as the error.

    5. `CommonError.translate/3` pattern-matches on the `ErrorContext`,
       extracts the hook module, and re-translates the inner `value`
       with the hook module in the options.

    6. The hook module's callbacks customize the translation of the
       inner error value.
  """

  @type t :: %__MODULE__{
          value: term(),
          hook_module: module()
        }

  @enforce_keys [:value, :hook_module]
  defstruct [:value, :hook_module]
end
