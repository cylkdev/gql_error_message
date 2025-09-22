defmodule GQLErrorMessage.ClientError do
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
  Create a new `GQLErrorMessage.ClientError`.
  """
  def new(opts \\ [])

  def new(opts) when is_map(opts) do
    opts |> Map.to_list() |> new()
  end

  def new(opts) do
    opts |> NimbleOptions.validate(@definition) |> then(&struct!(__MODULE__, &1))
  end

  @doc """
  Convert a `GQLErrorMessage.ClientError` to a JSONable map.
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
