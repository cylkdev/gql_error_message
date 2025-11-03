defmodule GQLErrorMessage.Spec do
  @moduledoc """
  Defines the specification for a GraphQL error.

  This struct contains the core properties that define how an error should be
  categorized and what information it should contain. Specs are stored in and
  retrieved from a `Repo` module (e.g., `GQLErrorMessage.DefaultCodex`).

  ## Fields

    * `:operation` - The GraphQL operation type (`:query`, `:mutation`, or `:subscription`).
    * `:kind` - The category of error (`:client_error` or `:server_error`).
    * `:code` - A unique atom identifying the error (e.g., `:bad_request`).
    * `:message` - The default message for the error.
    * `:extensions` - A map of additional, arbitrary data.
  """
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

  @doc """
  Creates a new `Spec` struct.

  Accepts a keyword list or a map of options.

  ## Options

    * `operation` (*required*) - The GraphQL operation type.
    * `kind` (*required*) - The error kind (`:client_error` or `:server_error`).
    * `code` (*required*) - The error code atom.
    * `message` (*required*) - The default error message.
    * `extensions` - A map of additional data. Defaults to `%{}`.
  """
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
