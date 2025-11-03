defmodule GQLErrorMessage.ServerError do
  @moduledoc """
  Represents a server-side error in a GraphQL response.

  This struct is used for internal server errors, such as database connection
  failures or other unexpected issues. It corresponds to a top-level error in
  the GraphQL response.

  ## Fields

    * `:message` - A string describing the error.
    * `:extensions` - A map containing additional, arbitrary data about the error.
  """
  alias GQLErrorMessage.Serializer

  defstruct [:message, :extensions]

  @type t :: %__MODULE__{
          message: String.t(),
          extensions: map()
        }

  @definition [
    message: [
      type: :string,
      required: true
    ],
    extensions: [
      type: :map,
      default: %{}
    ]
  ]

  @doc """
  Creates a new `ServerError` struct.

  Accepts a keyword list or a map of options.

  ## Options

    * `message` (*required*) - The error message.
    * `extensions` - A map of additional data. Defaults to `%{}`.
  """
  def new(opts \\ [])

  def new(opts) when is_map(opts) do
    opts |> Map.to_list() |> new()
  end

  def new(opts) do
    opts |> NimbleOptions.validate(@definition) |> then(&struct!(__MODULE__, &1))
  end

  @doc """
  Converts a `GQLErrorMessage.ServerError` to a JSON-serializable map.

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
