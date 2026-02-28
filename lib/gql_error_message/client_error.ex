defmodule GQLErrorMessage.ClientError do
  @moduledoc """
  Represents a client-facing input validation error in a GraphQL response.

  A `ClientError` describes a problem with user-supplied input, such as a
  missing required field or an invalid email format. It carries two pieces
  of information: the path to the invalid field and a human-readable error
  message.

  In an Absinthe schema, `ClientError` structs are placed inside a
  `user_errors` list on the mutation payload so the client can display
  per-field validation messages. For query operations, client errors are
  promoted to server errors (top-level `errors` array) because queries
  do not have a payload object to hold them.

  You normally do not create `ClientError` structs yourself. The built-in
  translator modules (`GQLErrorMessage.CommonError.ErrorMessageTranslator` and
  `GQLErrorMessage.CommonError.ChangesetTranslator`) produce them automatically
  when they translate resolver errors. If you are writing a custom
  translator, use `new/2` to build a `ClientError`.

  ## Fields

    * `:field` — a list of atoms representing the path to the invalid
      input field. For example, `[:email]` points to the top-level
      `email` input field, and `[:address, :zip_code]` points to a
      nested `zip_code` field inside an `address` input object. An
      empty list `[]` means the error applies to the input as a whole
      rather than to a specific field.

    * `:message` — a human-readable string describing the validation
      error, such as `"is invalid"` or `"can't be blank"`.

  ## Examples

      iex> GQLErrorMessage.ClientError.new([:email], "is invalid")
      %GQLErrorMessage.ClientError{field: [:email], message: "is invalid"}

      iex> GQLErrorMessage.ClientError.to_map(%GQLErrorMessage.ClientError{field: [:email], message: "is invalid"})
      %{field: [:email], message: "is invalid"}

  """

  defstruct [:field, :message]

  @type t :: %__MODULE__{
          field: list(),
          message: String.t()
        }

  @doc """
  Creates a new `ClientError` struct.

  The `field` argument is a list of atoms representing the path to the
  invalid input field. Pass an empty list `[]` when the error applies
  to the input as a whole.

  The `message` argument is a human-readable string describing the error.

  ## Examples

      iex> GQLErrorMessage.ClientError.new([:email], "is invalid")
      %GQLErrorMessage.ClientError{field: [:email], message: "is invalid"}

      iex> GQLErrorMessage.ClientError.new([:address, :zip_code], "must be 5 digits")
      %GQLErrorMessage.ClientError{field: [:address, :zip_code], message: "must be 5 digits"}

      iex> GQLErrorMessage.ClientError.new([], "is required")
      %GQLErrorMessage.ClientError{field: [], message: "is required"}

  """
  @spec new(list(), String.t()) :: t()
  def new(field, message) when is_list(field) and is_binary(message) do
    %__MODULE__{field: field, message: message}
  end

  @doc """
  Converts a `ClientError` struct to a plain map for JSON serialization.

  The returned map has the same `:field` and `:message` keys as the
  struct. This is used internally by `GQLErrorMessage.Absinthe.Middleware`
  to place user errors into the Absinthe resolution value.

  ## Examples

      iex> error = GQLErrorMessage.ClientError.new([:email], "is invalid")
      ...> GQLErrorMessage.ClientError.to_map(error)
      %{field: [:email], message: "is invalid"}

  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = error) do
    %{field: error.field, message: error.message}
  end
end
