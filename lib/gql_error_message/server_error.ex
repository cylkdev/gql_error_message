defmodule GQLErrorMessage.ServerError do
  @moduledoc """
  Represents a server-side error in a GraphQL response.

  A `ServerError` describes an internal failure that the client cannot fix
  by changing their input — for example, a database connection timeout or
  an unexpected exception in business logic. These errors appear in the
  top-level `errors` array of the GraphQL response, and the corresponding
  `data` field is set to `nil`.

  The GraphQL specification allows an `extensions` map on each error
  object for carrying additional machine-readable metadata. The
  `ServerError` struct includes an `:extensions` field for this purpose.
  When `GQLErrorMessage.CommonError.ErrorMessageTranslator` produces a `ServerError`,
  it populates `extensions` with the uppercased HTTP status code (for
  example, `%{code: "INTERNAL_SERVER_ERROR"}`) and any extra data from
  the `ErrorMessage` details.

  You normally do not create `ServerError` structs yourself. The built-in
  translator modules produce them automatically. If you are writing a
  custom translator, use `new/2` to build a `ServerError`.

  ## Fields

    * `:message` — a human-readable string describing the error, such as
      `"database connection failed"` or `"Service currently unavailable"`.

    * `:extensions` — a map of additional machine-readable data about
      the error. Defaults to an empty map `%{}`. Common keys include
      `:code` (an uppercased string like `"INTERNAL_SERVER_ERROR"`) and
      any domain-specific metadata the translator includes.

  ## Examples

      iex> GQLErrorMessage.ServerError.new("db connection failed")
      %GQLErrorMessage.ServerError{message: "db connection failed", extensions: %{}}

      iex> GQLErrorMessage.ServerError.new("db failed", %{code: "INTERNAL_SERVER_ERROR"})
      %GQLErrorMessage.ServerError{message: "db failed", extensions: %{code: "INTERNAL_SERVER_ERROR"}}

  """

  alias GQLErrorMessage.Serializer

  defstruct [:message, :extensions]

  @type t :: %__MODULE__{
          message: String.t(),
          extensions: map()
        }

  @doc """
  Creates a new `ServerError` struct.

  The `message` argument is a human-readable string describing the error.

  The optional `extensions` argument is a map of additional metadata to
  include in the GraphQL error response. It defaults to an empty map `%{}`.

  ## Examples

      iex> GQLErrorMessage.ServerError.new("service unavailable")
      %GQLErrorMessage.ServerError{message: "service unavailable", extensions: %{}}

      iex> GQLErrorMessage.ServerError.new("timeout", %{code: "GATEWAY_TIMEOUT", retry_after: 30})
      %GQLErrorMessage.ServerError{message: "timeout", extensions: %{code: "GATEWAY_TIMEOUT", retry_after: 30}}

  """
  @spec new(String.t(), map()) :: t()
  def new(message, extensions \\ %{}) when is_binary(message) and is_map(extensions) do
    %__MODULE__{message: message, extensions: extensions}
  end

  @doc """
  Converts a `ServerError` struct to a plain map for JSON serialization.

  The returned map has `:message` and `:extensions` keys. The
  `:extensions` value is recursively converted to JSON-safe values
  using `GQLErrorMessage.Serializer`, which means atoms become strings,
  dates become ISO 8601 strings, and structs become maps with `:struct`
  and `:data` keys.

  This function is used internally by `GQLErrorMessage.Absinthe.Middleware`
  to place server errors into the Absinthe resolution errors list.

  ## Examples

      iex> error = GQLErrorMessage.ServerError.new("failed", %{code: "INTERNAL_SERVER_ERROR"})
      ...> GQLErrorMessage.ServerError.to_map(error)
      %{message: "failed", extensions: %{code: "INTERNAL_SERVER_ERROR"}}

  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = error) do
    %{
      message: error.message,
      extensions: Serializer.to_jsonable_map(error.extensions)
    }
  end
end
