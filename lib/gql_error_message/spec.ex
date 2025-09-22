defmodule GQLErrorMessage.Spec do
  defstruct [:operation, :kind, :code, :message, :extensions]

  @type t :: %__MODULE__{
          operation: atom(),
          kind: atom(),
          code: atom(),
          message: String.t(),
          extensions: map()
        }

  @operations [:mutation, :query, :subscription]

  @definition [
    operation: [
      type: {:in, @operations},
      required: true
    ],
    kind: [
      type: {:in, [:client_error, :server_error]},
      required: true
    ],
    code: [
      type: :atom,
      required: true
    ],
    message: [
      type: :string,
      required: true
    ],
    extensions: [
      type: :map,
      default: %{}
    ]
  ]

  def new(opts) when is_map(opts) do
    opts
    |> Map.to_list()
    |> new()
  end

  def new(opts) do
    opts
    |> NimbleOptions.validate!(@definition)
    |> then(&struct!(__MODULE__, &1))
  end
end
