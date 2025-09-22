defmodule GQLErrorMessage.ServerError do
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
  Create a new `GQLErrorMessage.ServerError`.
  """
  def new(opts \\ [])

  def new(opts) when is_map(opts) do
    opts |> Map.to_list() |> new()
  end

  def new(opts) do
    opts |> NimbleOptions.validate(@definition) |> then(&struct!(__MODULE__, &1))
  end

  @doc """
  Convert a `GQLErrorMessage.ServerError` to a JSONable map.
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
