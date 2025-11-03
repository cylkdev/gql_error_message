defmodule GQLErrorMessage.ClientError do
  @moduledoc """
  Represents a client-side error that can be returned in a
  GraphQL response.

  This struct is typically used for input validation errors
  and corresponds to a user error in the GraphQL response,
  pointing to a specific field.

  ## Fields

    * `:field` - A list of atoms or strings representing the
      path to the invalid input field.

    * `:message` - A string describing the error.
  """
  alias GQLErrorMessage.Serializer

  defstruct [:field, :message]

  @type t :: %__MODULE__{
          field: list(),
          message: String.t()
        }

  @definition [
    field: [
      type: :list,
      required: true
    ],
    message: [
      type: :string,
      required: true
    ]
  ]

  @doc """
  Creates a new `ClientError` struct.

  Accepts a keyword list or a map of options.

  ## Options

    * `field` (*required*) - The path to the invalid field.
    * `message` (*required*) - The error message.
  """
  def new(opts \\ [])

  def new(opts) when is_map(opts) do
    opts |> Map.to_list() |> new()
  end

  def new(opts) do
    opts |> NimbleOptions.validate(@definition) |> then(&struct!(__MODULE__, &1))
  end

  @doc """
  Converts a `GQLErrorMessage.ClientError` to a JSON-serializable map.

  ## Options

    * `:serializer` - The module to use for serialization.
  """
  def to_jsonable_map(%__MODULE__{} = e, opts) do
    e
    |> Map.from_struct()
    |> serializer(opts).to_jsonable_map()
  end

  defp serializer(opts) do
    opts[:serializer] || Serializer
  end
end
