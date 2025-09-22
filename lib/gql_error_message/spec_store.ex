defmodule GQLErrorMessage.SpecStore do
  @callback get(op :: atom(), code :: atom()) :: GQLErrorMessage.Spec.t() | nil

  def get(spec_store, op, code) do
    spec_store.get(op, code)
  end
end
