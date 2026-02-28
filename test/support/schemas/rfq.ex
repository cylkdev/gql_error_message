defmodule GQLErrorMessage.Support.Schemas.Rfq do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias GQLErrorMessage.Support.Schemas.Rfq.CommercialResponse

  @primary_key false
  embedded_schema do
    embeds_many :commercial_responses, CommercialResponse
  end

  def changeset(struct_or_changeset, attrs \\ %{}) do
    struct_or_changeset
    |> cast(attrs, [])
    |> cast_embed(:commercial_responses, with: &CommercialResponse.changeset/2)
  end
end

defmodule GQLErrorMessage.Support.Schemas.Rfq.CommercialResponse do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :body, :string
  end

  def changeset(struct_or_changeset, attrs \\ %{}) do
    struct_or_changeset
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
