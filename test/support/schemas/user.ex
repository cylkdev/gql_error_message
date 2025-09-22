defmodule GQLErrorMessage.Support.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :age, :integer
  end

  def changeset(struct_or_changeset, attrs \\ %{}) do
    struct_or_changeset
    |> cast(attrs, [:name, :age])
    |> validate_required([:name])
    |> validate_number(:age, greater_than_or_equal_to: 0)
  end
end
