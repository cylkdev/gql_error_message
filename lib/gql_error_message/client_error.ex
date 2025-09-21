defmodule GQLErrorMessage.ClientError do
  defstruct [:field, :message]

  @type t :: %__MODULE__{
          field: list(),
          message: String.t()
        }
end
