defmodule GQLErrorMessage.Absinthe.Type do
  @moduledoc false
  use Absinthe.Schema.Notation

  object :user_error do
    field :field, list_of(:string)
    field :message, :string
  end

  defmacro user_error_payload_fields do
    quote do
      field :user_errors, list_of(:user_error)
    end
  end
end
