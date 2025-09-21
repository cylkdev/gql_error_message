defmodule GQLErrorMessage.Spec do
  defstruct [:operation, :kind, :code, :message, :extensions]

  @type t :: %__MODULE__{
          operation: atom(),
          kind: atom(),
          code: atom(),
          message: String.t(),
          extensions: map()
        }
end
