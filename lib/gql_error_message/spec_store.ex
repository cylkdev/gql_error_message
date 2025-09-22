defmodule GQLErrorMessage.SpecStore do
  @callback get_spec(op :: atom(), code :: atom()) :: GQLErrorMessage.Spec.t() | nil

  def get_spec(spec_store, op, code) do
    spec_store.get_spec(op, code)
  end
end
