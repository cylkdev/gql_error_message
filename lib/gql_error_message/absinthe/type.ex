defmodule GQLErrorMessage.Absinthe.Type do
  @moduledoc """
  Defines a standard `user_error` object and macro for Absinthe schemas.

  This module provides helpers for creating consistent error-handling fields in
  your GraphQL schema, particularly for mutation payloads.

  ## Usage

  Import this module into your schema and use the `user_error_payload_fields`
  macro within your payload objects.

      object :my_payload do
        import_fields :user_error_payload_fields
        field :result, :my_type
      end

  This will automatically add a `user_errors` field to your payload, which is a
  list of `user_error` objects.

  > #### Warning {: .warning}
  >
  > This module requires `:absinthe` as a dependency.
  """
  use Absinthe.Schema.Notation

  object :user_error do
    field :field, list_of(:string)
    field :message, :string
  end

  @doc """
  A macro that injects a `user_errors` field into an Absinthe object.

  This field is defined as a list of `:user_error` objects.
  """
  defmacro user_error_payload_fields do
    quote do
      field :user_errors, list_of(:user_error)
    end
  end
end
