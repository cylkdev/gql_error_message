defmodule GQLErrorMessage.ServerError do
  defstruct [:message, :extensions]

  @type t :: %__MODULE__{
          message: String.t(),
          extensions: map()
        }
end
